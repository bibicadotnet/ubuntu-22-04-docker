#!/bin/bash

# Thực thi lệnh sudo và nhập shell
sudo -s

# Chuyển về thư mục home của người dùng
cd ~

# Tải file script từ GitHub
curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh

# Chạy script đã tải với các tham số cần thiết
bash reinstall.sh ubuntu 22.04 --minimal --ssh-key "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNbQpTTc/rFDLKBYGC1CIYBbygRkP6lmEI2/9RGG/7u5+OxMgHCes5CIU6he/lx4bTGI238cJ082HNXGPnP6W9aKaRBKcnq9Wbii1AzdGtajsh3PtfOebH+5fZjtrSaWbqN7oFbFoZC1JkYEYP7lF3hd4xh6XRpDSWzNh+N99Tjjo3CP8a8k0EwGGGIJ/Mhfvs9RTTr6zyvDmWDKSqPddmBM2WFnpsS4TEYzZFUj+2vuqBR7BXd5WWZnK86wndD4wZedwD8qhIzgpDYM8ZNOBDt8MENbA8xw3ZzcSvXByzXaU5xFzkt7g8QJFEj6qa3wvxLUcnznz48RQGmCnFK4F3 ssh-key-2023-06-18" --ssh-port 2224
