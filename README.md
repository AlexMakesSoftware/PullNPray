# README.md

This is a proof of concept; A collection of scripts to help with the setup of a continual delivery pipeline (created for django projects but I'm sure it could easily be adapted for your needs) where your company policy prohibits any 'dialing in' to the local network. Which regretably means... dialing out polling.

NOTE: Don't just run these scripts as-is, you need to configure things manually for your setup.

Why 'Pull and pray'? These scripts don't *check* you've done anything sensible like *actually tested your code.* It makes no assumptions other than the code is there and it's ready for deployment - hence the term 'pull and pray'.

Typically, you want your nginx serving content from something like gunicorn, both of which you probably want to run as services. I'm assuming you've already set up nginx (or equivalent) to forward localhost:8000, or whatever you've chosen and you know what you're doing with that.

## Installation
I put all my polling script content in /opt/git_pollers/todo_django (where the last part of the path is the application this setup relates to - you could have multiple pollers).
The application should go in /var/www/projects/todo_django and the static content in say /www/static.

Make sure all your scripts are executable.
```
chmod +x *.sh
```

## Users, groups and permissions
You need to create an account with permissions to pull, redploy and restart the gunicorn service. I made an account called 'gunicorn' of a group 'hosted_apps' - to which I also added my user account as a member (for ease of installation).
The application should be installed in it's own directory, owned by this group, with permisisons inherited (because you'll be rewriting the contents of this a lot). You probably want to grant the group that the gunicorn user is a member of write access to it (I did, because in the POC I was using an sqlite database, that the system need write access to):
```
sudo chown -R :hosted_apps /var/www/projects
sudo chmod -R g+w /var/www/projects
sudo chmod g+s /var/www/projects
```

The deployment script will invariably end with a request to restart the gunicorn service and to do that, your gunicorn user will need sudoer permission (because this is an unattented process and nobody will be around to type in the admin password for it). We're going to grant everyone in the hosted_apps group permission to restart the gunicorn service:
```
# sudo visudo
```
Add this line to the end:
```
%hosted_apps ALL = NOPASSWD: /bin/systemctl restart todo_gunicorn.service
```
Now test you can execute this without sudo permission:
```
sudo systemctl restart todo_gunicorn.service
```
Do not proceed until this works (wihtout a password prompt).


## SSH Deployment key
Your polling script needs to be able to connect to github without asking for a password. This should be read-only access to your repository. DO NOT make it a writeable!

I stored my key in /etc/ssh-agent-service/deploy-keys/ and called it deploy_key_ed25519. Don't store it in your user home's .ssh folder and be careful not to overwrite your existing git ssh keys.

Go to the repository you want to poll. Click 'settings' in the menu, 'deploy keys' in the sidebar. Add a deploy key for 'deploy_key_ed25519' and **make sure it's read only!**

I created a service to start the ssh agent and add this key to it automatically when the machine boots. You can see the installation file 'ssh-agent.service' and the isntaller 'install_ssh_agent_key.ssh'.

Because I wanted to avoid confusing the system with my userr accounts key, this meant I needed to edit my ssh config for my user account, to create different domain names for different purposes. Ths is just because I had a personal account on the system that I used to do development as well as this POC, if you find yourself in the same boat, do this:

```
Host github.com
  Hostname github.com
  User git
  IdentityFile ~/.ssh/github_ed25519
Host github.com-repo-todo
  Hostname github.com
  IdentityFile /etc/ssh-agent-service/deploy-keys/deploy_key_ed25519
```
And then change the url used in your polling script to use the domain 'github.com-repo-todo'. This will ensure that the deploy key is used for fetching the latest version of the 'todo' app but your private key is used for development and whatever other dealings you have with github.


## Deployment script
This is mentioned in the polling file as deploy.sh but none is provided. This is because your deployment script needs to be specific to your project. An example file is provided called 'example_deploy_script.sh' which might meet all your requiremetns but you are encouraged to write your own and think about it, rather than just take what I've provided at face value.

## Gunicorn service
You'll need to create a gunciron.service file. I suggest naming it something like gunicorn.app_name.service, so that you know which gunicorn service controls which apps you install (if you're installing multiple apps, which you probably will). Edit the example_install_gunicorn.sh as you see fit - if you've renamed the gunicorn.service file you'll need to rename it in that script too.

## Suggested testing:
Install your ssh agent first. Then test:
```
ssh -T github.com-repo-todo
```
If it's working properly it won't ask you for a password.

Then check your poller works by just manually running:
```
./poll_git.sh
```
Make sure it updates if the git repo changes.

This will check your deployment script works too.

Check your app runs properly now.

If all has gone according to plan... then congratualations. You can now install the poller as a cron job.

```
sudo nano /etc/crontab
```
Add this line:
```
*/5 * * * * gunicorn /path/to/your/poller_script.sh
```
That will run the poller every five minutes.
Finally:
```
sudo systemctl restart cron
```
To make your changes active.
