### health-check.sh

#### MIT Licence

`health-check.sh` is a bash script utilizing netcat to detect the health of multiple hosts on specified port.

#### Pre-requisites

* netcat
* timeout

#### Install timeout

The timeout command is a part of the GNU core utilities package, which is installed on almost any Linux distribution

Run command `nc` first to check if it is already installed.

* Mac : `brew install coreutils`

#### Install Netcat 

Run command `nc` first to check if it is already installed.

* Mac : `brew install netcat`
* Debian, Ubuntu: `sudo apt-get install netcat`
* Alipne: `apk add -update netcat-openbsd`

#### Basic Usage 
```
./health-check.sh <timeout> <host1>:<port1> <host2>:<port2> .... <hostn>:<portn>
```

##### Sample 1 - Check two hosts with a shared 90 seconds timeout value

```sh
./health-check.sh 90 example.com:80 google.com:80 
```

_Output:_

```sh
Checking if example.com:80 responds... (Timeout 90 seconds)
connection succesfull example.com:80
Checking if google.com:80 responds... (Timeout 90 seconds)
connection succesfull google.com:80
```

#### Advanced Usage

```sh
./health-check.sh <timeout> <host1>:<port1>:<timeout1> <host2>:<port2>:<timeout2> .... <hostn>:<portn>:<timeoutn>
```

##### Sample 2 - Check three hosts with a shared 90 seconds timeout value and custom timeout values where specified

```sh
./health-check.sh 90 example.com:80:5 google.com:80:10 opendns.com:80
```

_Output:_

```sh
Checking if example.com:80 responds... (Timeout 5 seconds)
connection succesfull example.com:80
Checking if google.com:80 responds... (Timeout 10 seconds)
connection succesfull google.com:80
Checking if opendns.com:80 responds... (Timeout 90 seconds)
connection succesfull opendns.com:80
```

##### Sample 3- Check two hosts with separate timeout values of 5 and 10 seconds respectively

```sh
./health-check.sh example.com:81:5 google.com:80:10
```

_Output:_

```sh
Checking if example.com:81 responds... (Timeout 5 seconds)
connection failed example.com:81 within 5 seconds.
```

It fails after 5 seconds since example.com does not respond on port 81. After first failure scripts exits with exit code 1.

##### Default Values

* `time_out_default=1` # Default timeout value is 1 seconds if not indicated.
* `retry_interval=1` # netcat will be run in 1 second intervals. It can be changed inside the code

If <timeout> is discarded, default value is assigned

```sh
./health-check.sh example.com:80
```

Timeout is 1 second.

_Output:_

```sh
Checking if example.com:80 responds... (Timeout 1 seconds)
connection succesfull example.com:80
```
