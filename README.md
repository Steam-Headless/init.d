# Community Init.d script for Steam Headless

A collection of scripts that can be executed on Steam Headless container startup

---

## Installation

Inside the container, run:
```
git clone https://github.com/Steam-Headless/init.d.git ${USER_HOME:?}/init.d
```

Copy any scripts that you wish to use from the `${USER_HOME:?}/init.d/scripts` directory to the `${USER_HOME:?}/init.d` directory.

Restart the container.
