{ ... }:
{
  programs.fish = {
    enable = true;
    preferAbbrs = true;
    generateCompletions = true;

    shellAliases = {
      cat = "bat";
      cdtmp = "cd (mktemp -d)";
      l = "eza --icons";
      ls = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -l --git --octal-permissions";
      lla = "eza --icons -a -l --git --octal-permissions";
      lt = "br";
      docker-compose = "docker compose";
      awslocal = "AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws --endpoint-url=http://localhost:4566";
    };

    shellAbbrs = {
      k = "kubectl";
      "!!" = { function = "bang_bang"; position = "anywhere"; };
      pls = { function = "sudo_bang_bang"; };

      g = "git";
      ga = "git add";
      gd = "git diff";
      gint = "git init";
      grs = "git reset";
      grss = "git reset --soft";
      grsf = "git reset --hard";
      gr = "git restore";
      "gr-" = "git restore --staged";
      gs = "git status";
      gst = "git stash";
      gstf = "git stash --include-untracked";
      gstp = "git stash pop";
      gstl = "git stash list";
      gsw = "git switch";
      gsc = "git switch -c";
      gb = "git branch";
      gta = "git tag";
      gpl = "git pull";
      gplr = "git pull --rebase";
      gps = "git push";
      gpsf = "git push -f";
      gpsup = "git push --set-upstream (git remote) (git rev-parse --abbrev-ref HEAD)";
      grb = "git rebase";
      grpo = "git rebase --onto";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      gcmsg = "git commit -m";
      gamend = "git commit --amend -C HEAD";
      gcl = "gh repo clone";
      gsq = "git reset (git merge-base main (git rev-parse --abbrev-ref HEAD))";
      gwl = "git worktree list";
      gwa = "git worktree add";
      gwr = "git worktree remove";
      gwrf = "git worktree remove --force";

      dk = "docker";
      dkc = "docker container";
      dkcr = "docker container run";
      dkcs = "docker container stop";
      dkce = "docker container exec -it";
      dc = "docker compose";
      dcu = "docker compose up";
      dcd = "docker compose down";
      dce = "docker compose exec";

      clone_git_repositories = {
        regex = ".+\\.git";
        position = "command";
        function = "gclone";
      };
    };

    interactiveShellInit = (builtins.readFile ./fish-functions/herd.fish) + ''
      set fish_greeting

      if test "$TERM_PROGRAM" = ghostty
          set -gx TERM xterm-256color
      end
    '';

    functions = {
      bang_bang = {
        description = "expande !! para o último comando";
        body = ''echo $history[1]'';
      };

      sudo_bang_bang = {
        description = "expande pls para sudo + último comando";
        body = ''echo "sudo $history[1]"'';
      };

      fish_command_not_found.body = ''__fish_default_command_not_found_handler $argv'';

      gclone.body = builtins.readFile ./fish-functions/gclone.fish;
      atuin-login.body = builtins.readFile ./fish-functions/atuin-login.fish;
      md.body = builtins.readFile ./fish-functions/md.fish;
      pbcopy.body = builtins.readFile ./fish-functions/pbcopy.fish;
      pbpaste.body = builtins.readFile ./fish-functions/pbpaste.fish;
      pi-seccomp-off.body = builtins.readFile ./fish-functions/pi-seccomp-off.fish;
      rec-session.body = builtins.readFile ./fish-functions/rec-session.fish;
      y.body = builtins.readFile ./fish-functions/y.fish;
    };
  };
}
