from __future__ import with_statement
from fabric.api import *
from fabric.contrib.files import exists
from fabric.contrib.console import confirm


STAGING_ROOT = "${staging-root}"
PRODUCTION_ROOT = "${production-root}"
SCRIPT_NAME = "${control-script}"


def test():
    local('./bin/%s test' % SCRIPT_NAME)


def copyjson():
    put('*.json', STAGING_ROOT)
    
    
def make_archive(version="HEAD"):
    local('git archive --format=tar --prefix=%s/ %s | gzip >%s-%s.tar.gz' % (
        SCRIPT_NAME, version, SCRIPT_NAME, version))


def action(action=None, server="staging"):
    if action:
        if confirm("%s %s server?" % (action, server)):
            if server == "staging":
                with cd('%s/%s' % (STAGING_ROOT, SCRIPT_NAME)):
                    run('sh ./bin/%s.sh %s' % (SCRIPT_NAME, action))

            elif server == "production":
                pass
    else:
        abort("Invalid action")


def deploy(server="staging", version="HEAD"):
    if confirm("Deploy %s to %s server?" % (version, server)):
        if server == "staging":
            # Shouldn't really disable tests, but not critical for this site
            local('./bin/%s test' % SCRIPT_NAME)

            make_archive(version)
            put('%s-%s.tar.gz' % (SCRIPT_NAME, version), STAGING_ROOT)

            with cd(STAGING_ROOT):
                app_script = './%s/bin/%s.sh' % (SCRIPT_NAME, SCRIPT_NAME)

                # Stop the process if it's running before continuing
                if exists(app_script):
                    run('sh %s stop' % app_script)
                run('tar zxvf %s-%s.tar.gz' % (SCRIPT_NAME, version))

            with cd('%s/%s' % (STAGING_ROOT, SCRIPT_NAME)):
                run('python2.7 bootstrap.py -c production.cfg')
                run('./bin/buildout -c staging.cfg')

        elif server == "production":
            # Shouldn't really disable tests, but not critical for this site
            local('./bin/%s test' % SCRIPT_NAME)

            make_archive(version)
            put('%s-%s.tar.gz' % (SCRIPT_NAME, version), PRODUCTION_ROOT)

            with cd(PRODUCTION_ROOT):
                app_script = './%s/bin/%s.sh' % (SCRIPT_NAME, SCRIPT_NAME)

                # Stop the process if it's running before continuing
                if exists(app_script):
                    run('sh %s stop' % app_script)

                run('tar zxvf %s-%s.tar.gz' % (SCRIPT_NAME, version))

            with cd('%s/%s' % (PRODUCTION_ROOT, SCRIPT_NAME)):
                run('python2.7 bootstrap.py -c production.cfg')
                run('./bin/buildout -c production.cfg')
                
    else:
        abort("Aborting at user request")

