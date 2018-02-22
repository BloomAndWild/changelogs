require 'github_api'
require 'pivotal-tracker'
require 'dotenv'

Dotenv.load("#{File.expand_path(File.dirname(__FILE__))}/.env")

Hashie.logger.level = 3

def github
  @github ||= Github.new basic_auth: ENV["GITHUB_USERNAME"] + ":" + ENV["GITHUB_TOKEN"]
end

def pivotal_project
  PivotalTracker::Client.token = ENV["PIVOTAL_TOKEN"]
  PivotalTracker::Project.find(ENV["PIVOTAL_ID"])
end

def release_pr
  pr = github.pull_requests.list(ENV["GITHUB_COMPANY"], ENV["GITHUB_REPO"]).find{ |pr|
    pr.base.ref == "master" && pr.head.ref == "staging"
  }
  if pr
    pr.number
  else
    fail "No release pull request"
  end
end

def get_for_pr pr_id
  items = {}
  unpivotalised_number = 1
  github.pull_requests.commits(ENV["GITHUB_COMPANY"], ENV["GITHUB_REPO"], pr_id).each do |c|
    commit_message = c["commit"]["message"]
    pivotal_id = /\#[0-9]{5,}/.match(c["commit"]["message"])&.to_s&.slice(1, 1000) || unpivotalised_number.to_s
    item = items[pivotal_id]
    item ||= []
    item.push(c["commit"])
    items[pivotal_id.to_s] = item
    unpivotalised_number += 1
  end

  return items
end

def changelog pr_id
  commits = get_for_pr(pr_id)
  log = []
  log.push "Backend/API release:"
  log.push "*ETA to live*: "
  log.push "PR: https://github.com/#{ENV["GITHUB_COMPANY"]}/#{ENV["GITHUB_REPO"]}/pull/#{pr_id}"
  log.push "URL: https://www.bloomdev.org, https://admin.bloomdev.org"
  project = pivotal_project
  i = 1
  commits.keys.each do |key|
    cs = commits[key]
    desc = cs.first['message'].strip.split("\n").map(&:strip).reject{ |d| d.empty? }.uniq
    message = desc.shift.delete("*")
    next if message =~ /^Merge/ || message =~ /^Bundle Update/

    log.push "──────────────────────────────────────"

    urls = cs.map do |c|
      c['url'].sub(
        "https://api.github.com/repos/#{ENV['GITHUB_COMPANY']}/#{ENV['GITHUB_REPO']}/git/commits/",
        "https://github.com/#{ENV['GITHUB_COMPANY']}/#{ENV['GITHUB_REPO']}/commit/"
      )[0..-35]
    end

    if key.size > 4
      pivotal_id = key
      story = project.stories.find(pivotal_id)
    end

    if story
      log.push "*#{i}. #{story.name}*"
    else
      log.push "*#{i}. #{message}*"
    end

    desc.each do |d|
      log.push "> #{d}"
    end

    if pivotal_id
      log.push ":pivotal: https://www.pivotaltracker.com/story/show/#{pivotal_id}"
    end

    log.push ":github: #{urls.join(", ")}"

    if story
      log.push ":bust_in_silhouette: #{story.requested_by}"
    else
      log.push ":bust_in_silhouette: "
    end

    i = i + 1
  end
  log
end

puts changelog(ENV["PR_ID"] || release_pr)
