# README.md

THis is a collection of scripts to help with the setup of a continual delivery pipeline (created for django projects but I'm sure it could easily be adapted for your needs) where your company policy prohibits any 'dialing in' to the local network. Which regretably means... dialing out polling.

NOTE: Don't just run these scripts as-is, you need to configure things manually for your setup.

Why 'Pull and pray'? These scripts don't *check* you've done anything sensible like *actually tested your code.* It makes no assumptions other than the code is there and it's ready for deployment - hence the term 'pull and pray'.

## Git Repo Poller
The poll_git.sh script should be placed somewhere sensible on the system and the permissions changed to make it executable.
```
chmod +x poll_git.sh
```
Modify the settings under 'Set your variables' in the poller script to match your individual needs.
You need to set up an ssh connection to your repository. See the [github documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) on this if you're using github but it typically amounts to:
```
ssh-keygen -t ed25519 -C "your.email@pm.me"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```
Then you need to change ~/.ssh/id_ed25519 in ssh-agent.service to point to wherever your key is, and then run install_ssh_agent_key.sh. This will install a service that will make sure the ssh agent is running and then add your key to it once the system has booted.

## Deployment script
This is mentioned in the polling file as $HOME/poller/$project/deploy.sh.
Typically, you want your nginx serving content from something like gunicorn, both of which you probably want to run as services. Configuring that is up to you but you want a script in deploy.sh which will stop and restart everything you need to. An example is provided in this project called 'example_install_gunicorn.sh'. You will need to adapt it for your individual needs, and provide a gunicorn.service file, as per your needs (an example is provided in example_gunicorn.service).


TODO: write up how you added a read-only deploy key for your ssh git clone command.
You MUST read these instructions, especially the bit about "Using multiple repositories on one server": https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys


