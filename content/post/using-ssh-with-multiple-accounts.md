+++
date = "2014-11-18T22:24:54-08:00"
draft = false
title = "Using SSH for private and work account on a Mac"
+++

> Disclaimer: I'm not a huge fan of configuring software; I'm primarily writing this to remember it for the future.

Using SSH instead of HTTPS to authenticate against services such as GitHub, Bitbucket or Heroku is very convenient, instead of typing a password for every interaction Mac OS simply exchanges SSH keys behind the scene. However, one can run into trouble when trying to use multiple accounts of the same service with SSH authentication. 

In this brief write-up I want to discuss how to set up multiple Bitbucket accounts with different associated SSH Keys.

##Two Bitbucket SSH keys on one machine

The key for setting up the SSH client to use multiple SSH keys for the same service is the SSH config file which resides in: `~/.ssh/config`

The config files remembers hosts to which you have previously connected using SSH and stores the associated SSH Key for each of them.

Per default SSH will use your main SSH key, which is typically stored in `~/.ssh/id_rsa`, to authenticate with servers and services.

Now let's assume you have two Bitbucket accounts, one for work and a second private account. When you did set up your private account you added `id_rsa` as your public SSH key. Now when you try to add the same key to your work account Bitbucket will display an error because that public key is already associated with a different account. Bitbucket will have to identify your account based on the provided SSH key, therefore each SSH key can only be used for a single account.

This means you will need to create a second pair of SSH keys for use with your work account using the following command:

	ssh-keygen -t rsa -C "your_email@example.com"
    
Terminal will prompt you for a file name for that new key - you can choose one that identifies the key as a work SSH key (e.g. company name). Now you have a second SSH key and can add that one to your work account on Bitbucket.

##Serving the right key

Now one problem remains. If you clone a Bitbucket repository, authenticating with SSH, SSH will by default always serve the `id_rsa` key which is associated with your personal account - that means you still won't be able to authenticate yourself with your work account and won't be able to interact with work repositories using SSH authentication.

Currently your SSH config file (`~/.ssh/config`) should look like similar to this:

	Host bitbucket.org
		IdentityFile ~/.ssh/id_rsa

Every time you connect to the host `bitbucket.org` you serve the `id_rsa` key, this setting has been established when you connected to this host the first time.

We have two options at this point: 

- specify which SSH key we want to send every time we connect to the remote server
- change our SSH config file to server the correct SSH key

The second option should mostly be preferred. 

##Using host alias names

We've just seen that the SSH client determines the SSH key based on the host name. That means we need two different host names for `bitbucket.org` depending on whether we want to use the personal or private account. Luckily the SSH config file lets us declare host aliases in the following way:

    Host bitbucket.personal
     HostName bitbucket.org
     IdentityFile ~/.ssh/id_rsa
     IdentitiesOnly yes
    
    Host bitbucket.work
     HostName bitbucket.org
     IdentityFile ~/.ssh/makegameswithus
     IdentitiesOnly yes
     
In the first line of each entry we store the alias. This can be any string you want, you'll need to use it whenever you connect to the actual host. 

The actual host name is stored in the second line. When you connect to a server using the string `bitbucket.work` it will be replaced by the actual host name `bitbucket.org` *and* the SSH client will know to send the specified `makegameswithus` SSH key instead of the default one.

The `IdentitiesOnly yes` entry defines that only the specified SSH key is served and not any other SSH keys that happen to be loaded by the SSH client at the time of the request.

Now, whenever you want to clone a work repository you can use your defined alias as the host name:

	git clone git@bitbucket.work:repo.git

And the SSH client will serve your work SSH key allowing you to authenticate with the Bitbucket server. Hooray!