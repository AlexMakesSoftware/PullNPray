#!/bin/bash

# Copy the gunicorn.service file to the systemd service directory
sudo cp gunicorn.service /etc/systemd/system/

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable and start the Gunicorn service
sudo systemctl enable gunicorn.service
sudo systemctl start gunicorn.service
