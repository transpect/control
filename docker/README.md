# transpect control Docker Container

Subversion, apache, and BaseX in a docker container.

It is not meant for production, only for development.

When transferring this solution to a production environment, remember to assign a different password to the BaseX admin user.
In the container, it has the password 'popesti'.

You will likely mount existing svn and passwd/authz directories.

BaseX will optionally modify the files in these directories (create repos, add/modify users/passwords, add/change authz settings). It is prudent to back up these files before running transpect-control in production.

# Building the container

```
docker build -t svn-server .
```

# Running the container

```
docker run -d -p 127.0.0.1:9080:80/tcp --name svn-server -it svn-server
```

It will start BaseX as a service before launching apache in the foreground.

Yes, we could have built a distinct BaseX container, and we might do so in the future.

# Log in to the container

```
docker exec -it svn-server bash
```

If the container isn’t running, there is an error and you can inspect the messages in Docker Desktop.

