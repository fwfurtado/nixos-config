{ ... }:
{
  programs.git = {
    enable = true;

    signing = {
      format = "ssh";
      key = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnjxWt9XUWWnP0ilRlAugrqYs0RKgfzn/3ZiyEKEENo";
      signByDefault = true;
      allowedSigners = ''
        fwfurtado@gmail.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGnjxWt9XUWWnP0ilRlAugrqYs0RKgfzn/3ZiyEKEENo
      '';
    };

    settings = {
      user = {
        name = "Mimi";
        email = "fwfurtado@gmail.com";
      };

      core = {
        autocrlf = "input";
        compression = 9;
        pager = "hunk pager";
        editor = "nvim";
      };

      diff = {
        context = 3;
        tool = "hunk";
      };

      difftool = {
        prompt = false;
        hunk.cmd = ''hunk difftool "$LOCAL" "$REMOTE" "$MERGED"'';
      };

      init.defaultBranch = "main";

      log = {
        abbrevCommit = true;
        graphColors = "blue,yellow,cyan,magenta,green,red";
      };

      push = {
        autoSetupRemote = true;
        default = "current";
        followTags = true;
      };

      pull = {
        rebase = true;
        ff = "only";
      };

      url."git@github.com:" = {
        insteadOf = "https://github.com/";
        pushInsteadOf = [
          "github:"
          "git://github.com/"
        ];
      };

      alias = {
        hdiff = ''-c core.pager="hunk pager" diff'';
        hshow = ''-c core.pager="hunk pager" show'';
      };
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.git_protocol = "ssh";
  };
}
