# Ubuntu Development Server Setup

**CentOS WordPress** is an installer for [CentminMod](http://centminmod.com/) (tested with and built for a [Digital Ocean VPS](https://www.digitalocean.com/?refcode=751743d45e36)). CentOS WordPress adds a **bleeding-edge web server stack** to your CentOS-based VPS.

## Features
+ Easy installation
+ Compiles software from source
+ Caches WordPress into RAM
+ Best security practices
+ Improvements to CentminMod

## Instructions
1. Set up a CentOS VPS (this script was built and tested CentOS WordPress with a 2GB 64-bit CentOS 6.4 [Digital Ocean VPS](https://www.digitalocean.com/?refcode=751743d45e36)
2. Log into the VPS with PuTTY (or another SSH client)
3. Enter `bash <(curl -s https://raw.github.com/MByteIO/CentOS-WordPress/master/install.sh)`
4. Follow the prompts and prosper

## Benchmarks
Nothing official yet but a pingdom score below 90% is rare even for a picture blog. Nginx test page gets 99% - 100% consistently.

## Technology Used
+ Nginx + FastCGICache - Bundles arguably the fastest web server with a server level static file caching
+ PHP-FPM + APC - Provides PHP support to Nginx with opcode caching
+ Memcached Server and Client - Distributed memory caching system (for cloud networks)
+ Pagespeed - Google's bleeding-edge website compression/optimization software
+ MariaDB - MySQL performance fork
+ Multi-Threaded Compression - Improves website load times by compressing files aggressively
+ CSF Firewall - Manages the firewall and uses real-time monitoring to protect against attacks
+ Automatic WordPress Installer - Custom WordPress installer
