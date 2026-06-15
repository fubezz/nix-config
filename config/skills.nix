{ ... }:

{
  # Manage ~/.claude/skills via home-manager.
  # Source of truth is skills/ in this repository — edit there, then nixrebuild.
  home.file = {
    ".claude/skills/csv-validation".source = ../skills/csv-validation;
    ".claude/skills/gcp-mail-triage".source = ../skills/gcp-mail-triage;
    ".claude/skills/interview".source = ../skills/interview;
    ".claude/skills/morning-briefing".source = ../skills/morning-briefing;
    ".claude/skills/peng-onboard-foundry-service".source = ../skills/peng-onboard-foundry-service;
    ".claude/skills/review-infrastructure-pull-request".source = ../skills/review-infrastructure-pull-request;
    ".claude/skills/review-ticket-human".source = ../skills/review-ticket-human;
    ".claude/skills/slack-to-jira".source = ../skills/slack-to-jira;
    ".claude/skills/monthly-rec-meeting-record".source = ../skills/monthly-rec-meeting-record;
  };
}
