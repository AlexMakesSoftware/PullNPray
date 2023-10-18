#!/bin/bash
projectpath="/var/www/projects/todo_django/"
venv="/var/www/projects/todo_django/.venv"
echo "Attempting to redeploy now."
cd "$projectpath"
source "$venv/bin/activate"
pip install -r requirements.txt

python manage.py migrate

# NOTE: to run this line without being prompted for a password, you'll need to add a line to your sudoers file
# sudo visudo
# add this:
# %hosted_apps ALL = NOPASSWD: /bin/systemctl restart todo_gunicorn.service
sudo systemctl restart todo_gunicorn.service
echo "Done. Check above for errors."
