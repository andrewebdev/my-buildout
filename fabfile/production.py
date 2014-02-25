import os
from fabric.api import *
from fabric.contrib.console import confirm


# Set up the production environment vars
env.hosts = []
env.user = ''

# Set some helpful global vars
SCRIPT_NAME = ''  # This should be the same as you bin script name
PROJECT_ROOT = ""  # Root folder on the server
projectroot = lambda *p: os.path.join(PROJECT_ROOT, *p)


@task
def make_archive(version="HEAD"):
    filename = "%s-%s.tar.gz" % (SCRIPT_NAME, version)
    local('git archive --format=tar %s | gzip >%s' % (version, filename))
    return filename


@task
def buildout():
    with cd(PROJECT_ROOT):
        run('./bin/buildout -c production.cfg')


@task
def deploy(version="HEAD"):
    if confirm("Deploy %s?" % version):
        archive = make_archive(version)
        put(archive, PROJECT_ROOT)
        with cd(PROJECT_ROOT):
            run('tar zxvf %s' % archive)
    else:
        abort("Aborting at user request")

