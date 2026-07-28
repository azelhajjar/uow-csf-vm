#!/bin/bash
sudo sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news
sudo systemctl restart motd-news.timer
