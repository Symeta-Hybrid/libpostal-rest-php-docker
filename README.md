# libpostal-rest-php Dockerfile

This Dockerfile sets up an Ubuntu machine and installs libpostal from source.
It also installs the official libpostal PHP bindings, as well as a Laravel application to forward the requests to libpostal.

For more information:

libpostal: https://github.com/openvenues/libpostal

php-postal: https://github.com/openvenues/php-postal

Laravel: https://laravel.com/docs/10.x

## Container configuration
Your container will be set up with Apache2 and PHP 8.2 FPM. Both of these are managed by supervisord.
Config files for all of these are included and set with sane defaults - feel free to adapt as necessary.

## Running your container
Build your container just as you always would. Pull the repo, cd to it and build:

    docker build -t libpostal-php .
After building, run your container:

    docker run --name="libpostal" -p 1234:80 -d -t libpostal-php:latest
Note: change the host port to suit your needs. 1234 was used in this example.
## Using the application
At this point, the Laravel application should be serving requests sent to the "parse" and "expand" endpoints.
Test this by sending a GET request as follows:

    http://localhost:1234/parse?query=1 Chiltern St, London W1U 7PA, United Kingdom
    http://localhost:1234/expand?query=513 Main St, Roosevelt Island, NY 10044
These will return a JSON response (respectively):

![JSON response parse](https://i.imgur.com/V2MhzR5.png)
![JSON response expand](https://i.imgur.com/3SfWRbp.png)
