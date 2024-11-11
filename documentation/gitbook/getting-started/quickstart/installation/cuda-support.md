# CUDA Support

Please be sure that you have correctly configured your NVIDIA Drivers and Docker to run with GPU --gpu support.&#x20;

pamac build nvidia-container-toolkit

Than you can run PANDORA container by appending "--gpus all"

```
docker run --gpus all --rm --detach --name genular --tty --interactive --env IS_DOCKER='true' --env TZ=Europe/London --oom-kill-disable --volume genular_frontend_latest:/var/www/genular/pandora --volume genular_backend_latest:/var/www/genular/pandora-backend --volume genular_data_latest:/mnt/usrdata --publish 3010:3010 --publish 3011:3011 --publish 3012:3012 --publish 3013:3013 genular/pandora:latest
```

If you dont get any error you are good!
