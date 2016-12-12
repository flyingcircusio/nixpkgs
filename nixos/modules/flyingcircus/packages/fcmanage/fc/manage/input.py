#! /run/current-system/sw/bin/env nix-shell
#! nix-shell -i python3 -p python34Packages.python -p python34Packages.requests2 -p python34Packages.click -I nixpkgs=/root/nixpkgs
#
# input sample
# {
#     "configuration":  {
#     "tls_key_password":  "P@ssw0rd",
#     "recv_buffer_size":  1048576,
#     "max_message_size":  2097152,
#     "bind_address":  "0.0.0.0",
#     "port":  12201,
#     "tls_enable":  false,
#     "use_null_delimiter":  true
#     },
#     "title":  "myNewGlobalGelfTcpInput",
#     "global":  true,
#     "type":  "org.graylog2.inputs.gelf.tcp.GELFTCPInput"
# }
# 201 -> success
# returns input id
#
# requests.post(api + '/system/inputs/', auth=(user, pw), json=data).text
# >>> '{"id":"57fe09c2ec3fa136a780adb9"}'
import click
import json
import requests


@click.command()
@click.option('-u', '--user', default='admin', show_default=True)
@click.option('-p', '--password', default='admin', show_default=True)
@click.argument('api')
@click.argument('input_conf')
@click.argument('sso_conf')
def cli(user, password, api, input_conf, sso_conf):
    """Configure a Graylog input node."""
    s = requests.Session()
    s.auth = (user, password)
    r = s.get(api + '/system/cluster/node')
    r.raise_for_status()
    data = json.loads(input_conf)
    data['node'] = r.json()['node_id']

    # check if there is input with this name currently configured, if so return
    r = s.get(api + '/system/inputstates')
    r.raise_for_status()
    for _input in r.json()['states']:
        if _input['message_input']['title'] == data['title']:
            return None

    # create input for UDP
    r = s.post(api + '/system/inputs', json=data)
    r.raise_for_status()
    # return r.json()['id']

    # autoconfigure sso-plugin
    data = json.loads(sso_conf)
    r = s.post(api + '/plugins/org.graylog.plugins.auth.sso/config', json=data)
    r.raise_for_status()


if __name__ == '__main__':
    cli()
