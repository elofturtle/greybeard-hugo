#!/usr/bin/env bash
bas="$(dirname $(readlink -f $0))"
source "${bas}/redeploy.conf" # webhook_secret, etc
cfg="${bas}/hooks.json"
echo '[
    ' > "${cfg}.tmp"
echo '{
    "id": "github",
    "execute-command": "changeme_base/redeploy.sh",
    "include-command-output-in-response": true,
    "include-command-output-in-response-on-error": true,
    "incoming-payload-content-type": "application/json",
    "success-http-response-code": 200,
    "response-message": "yay!",
    "command-working-directory": "changeme_base",
    "pass-arguments-to-command": [
        {
         "source": "string",
         "name": "--repo"
        },
      {
        "source": "payload",
        "name": "repository.name"
      }
    ],
    "trigger-rule": {
      "and": [
        {
          "match":
          {
            "type": "payload-hmac-sha1",
            "secret": "changeme_secret",
            "parameter":
            {
              "source": "header",
              "name": "X-Hub-Signature"
            }
          }
        },
        {
          "match":
          {
            "type": "value",
            "value": "refs/heads/master",
            "parameter":
            {
              "source": "payload",
              "name": "ref"
            }
          }
        }
      ]
    }
  }
' > "${cfg}.tmp"
]' >> "${cfg}.tmp"
sed -i "s/changeme_secret/${webhook_secret}/g" "${cfg}.tmp"
sed -i "s/changeme_base/${bas}/g" "${cfg}.tmp"
awk NF "${cfg}.tmp" > "${cfg}" # remove empty and whitespace lines
rm "${cfg}.tmp"
type -p jq &>/dev/null && cat "${cfg}" | jq
echo "Done"