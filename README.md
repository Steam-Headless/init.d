# Community Init.d script for Steam Headless

A collection of scripts that can be executed on Steam Headless container startup

---

## Installation

Inside the container, run:
```
git clone https://github.com/Steam-Headless/init.d.git ${USER_HOME:?}/init.d
```

Create a symlink of any scripts that you wish to use from the `${USER_HOME:?}/init.d/scripts` directory to the `${USER_HOME:?}/init.d` directory.
```
ln -sf "${USER_HOME:?}/init.d/scripts/install-es-de.sh" "${USER_HOME:?}/init.d/install-es-de.sh"
```

Each script in the `./scripts` directory should have instructions on what it does and how to use it. Read each one before creating a symlink.

Once you have configured this `~/init.d` directory with the scripts you wish for it to run, restart the container.

---

## Auto update these scripts

To setup an automatic update of the scripts in this repository, create a symlink of the `00-auto-update-init-scripts.sh` script:
```
ln -sf "${USER_HOME:?}/init.d/scripts/00-auto-update-init-scripts.sh" "${USER_HOME:?}/init.d/00-auto-update-init-scripts.sh"
```
