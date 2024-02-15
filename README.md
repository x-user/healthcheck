# DO NOT USE

Healthcheck not working on podman-compose (not tested on docker) if /bin/sh not available in container even when using CMD in heathcheck.test.

```sh
$ podman version 
Client:       Podman Engine
Version:      4.9.0
API Version:  4.9.0
Go Version:   go1.21.6
Built:        Wed Jan 24 13:07:27 2024
OS/Arch:      linux/amd64
```

```shell
$ podman inspect --format "{{json .State.Health }}" healthcheck_test | jq
{
  "Status": "unhealthy",
  "FailingStreak": 18,
  "Log": [
    {
      "Start": "2024-02-15T10:34:44.046709663+03:00",
      "End": "2024-02-15T10:34:44.131872722+03:00",
      "ExitCode": 1,
      "Output": ""
    },
```

## Reason

podman-compose up starts container with command bellow, as you can see there /bin/sh prepended to `--healthcheck-command` argument value.

```sh
podman create --name=healthcheck_test --label io.podman.compose.config-hash=b5184eebbcd6771431f65589acd3da493bee2c80599c8cbb1e22595b05923a72 --label io.podman.compose.project=healthcheck --label io.podman.compose.version=1.0.6 --label PODMAN_SYSTEMD_UNIT=podman-compose@healthcheck.service --label com.docker.compose.project=healthcheck --label com.docker.compose.project.working_dir=/home/x-user/src/healthcheck --label com.docker.compose.project.config_files=docker-compose.yaml --label com.docker.compose.container-number=1 --label com.docker.compose.service=test --net healthcheck_default --network-alias test --healthcheck-command /bin/sh -c /healthcheck' 'http://localhost:8080/ping --healthcheck-interval 5s --healthcheck-timeout 5s --healthcheck-retries 5 healthcheck_test
```

Co reason behind this behavior is how podman-compose convert this parameters to command line arguments for podman ([link](https://github.com/containers/podman-compose/blob/831caa627642695a621ad9e77b830b05d5fd050d/podman_compose.py#L1053-L1055)):

```py title="podman_compose.py" hl_lines="14-16"
    if healthcheck_test:
        # If it's a string, it's equivalent to specifying CMD-SHELL
        if is_str(healthcheck_test):
            # podman does not add shell to handle command with whitespace
            podman_args.extend(
                ["--healthcheck-command", "/bin/sh -c " + cmd_quote(healthcheck_test)]
            )
        elif is_list(healthcheck_test):
            healthcheck_test = healthcheck_test.copy()
            # If it's a list, first item is either NONE, CMD or CMD-SHELL.
            healthcheck_type = healthcheck_test.pop(0)
            if healthcheck_type == "NONE":
                podman_args.append("--no-healthcheck")
            elif healthcheck_type == "CMD":
                cmd_q = "' '".join([cmd_quote(i) for i in healthcheck_test])
                podman_args.extend(["--healthcheck-command", "/bin/sh -c " + cmd_q])
            elif healthcheck_type == "CMD-SHELL":
                if len(healthcheck_test) != 1:
                    raise ValueError("'CMD_SHELL' takes a single string after it")
                cmd_q = cmd_quote(healthcheck_test[0])
                podman_args.extend(["--healthcheck-command", "/bin/sh -c " + cmd_q])
            else:
                raise ValueError(
                    f"unknown healthcheck test type [{healthcheck_type}],\
                     expecting NONE, CMD or CMD-SHELL."
                )
        else:
            raise ValueError("'healthcheck.test' either a string or a list")
```
