
# Packer Saltstack Provisioner for Ubuntu

Tested with Ubuntu 20.04 and 22.04

Tested with arm64 and amd64 architectures

Add this script to the folder containing your Packer JSON and then add this to your Packer JSON file:


```
"provisioners": [
...
    {
        "type": "shell",
        "script": "salt-masterless.sh",
        "execute_command": "sudo -S bash -c '{{ .Vars }} {{ .Path }}'"
    }
...
]
```