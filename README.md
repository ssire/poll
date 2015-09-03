Oppidoc POLL application
========================

by Stéphane Sire <s.sire@oppidoc.fr>

Goal
----

The POLL application is a feedback questionnaire service platform

You can call it from 3rd party web applications to :

- upload and create questionnaires from XML Questionnaire specifications (POST a `Poll` document)
- upload and create (resp. cancel, close) orders with a unique id and custom variables to generate a unique page to run a questionnaire (POST an `Order` document)
- allow guest users (no login) to complete a questionnaire and post answers to a web hook inside a 3rd party application

It uses an XML Questionnaire specification language to define the questions and an optional web hook where to post the answers

Demonstration
-------------

The application comes with a _sample_ questionnaire (`samples/questionnaire1.xml`) and a sample order (`samples/order1.xml`). It also comes with a shell script to POST them to the application to simulate a third party application (see ``scripts/test.sh``).

Implementation
--------------

This is an eXist-DB application written with the XQuery application framework Oppidum

It uses the following (embedded) libraries :

- Bootstrap (2.3.1)
- AXEL 
- AXEL-FORMS

Installation
------------

Install eXist-DB (tested with version 2.2) into EXIST_HOME

Start eXist-DB

    cd EXIST_HOME
    ./bin/startup.sh &

The POLL application MUST be deployed side by side with the Oppidum framework into the same parent directory inside the `EXIST_HOME/webapp` directory of the eXist-DB installation to be run from the file system.

First create the common parent directory into EXIST_HOME/webapp (e.g. `projects`)

    cd EXIST_HOME/webapp
    mkdir projects
    
Second checkout oppidum and initialize oppidum

    cd EXIST_HOME/webapp/projects
    git clone https://github.com/ssire/oppidum.git
    git checkout exist-2.2
    cd oppidum/scripts
    ./bootstrap.sh password

Where _password_ is the admin password of your eXist-DB installation

Note that until the branch `exist-2.2` is merged into the `master` branch you need to switch explicitly to it first.

This should make a minimal installation of the Oppidum framework, you can check it  is running by opening [http://localhost:8080/exist/projects/oppidum](http://localhost:8080/exist/projects/oppidum) (please adapt the port to you eXist installation port if you changed the default one)

Then checkout the POLL application and initialize it 

    cd EXIST_HOME/webapp/projects
    git clone https://github.com/ssire/poll.git
    cd poll/scripts
    ./bootstrap.sh password

Where _password_ is the admin password of your eXist-DB installation. While running the `bootstrap.sh` script you need to enter `quit`and validate each time the launches the eXist-DB command line client to perform some database manipulation.

This should create and garnish a `/db/www/poll` collection and a `/db/sites/poll` collection.

Edit the `script/tests.sh` to set the running port of your eXist instance, then create the `sample` questionnaire from the `samples/questionnaire1.xml` specification with :

    cd EXIST_HOME/webapp/projects/poll/test
    ./test.sh questionnaire

You can then create an order from the `samples/order1.xml` specification with :

    cd EXIST_HOME/webapp/projects/poll/test
    ./test.sh create

Then you point your browser to [http://localhost:8080/exist/projects/poll/forms/azerty](http://localhost:8080/exist/projects/forms/azerty) to run the corresponding customized questionnaire you created.

Note that you can also open  [http://localhost:8080/exist/projects/poll/admin](http://localhost:8080/exist/projects/admin) using the _poll_ / _test_ user login to see the list of running individualized questionnaires.

The poll application requires a user in the DBA group to be able to execute the `modules/poll/poll.xsl` transformation to generate a questionnaire from its XML specification. The `scripts/bootstrap.sh` script creates an _xsl-agent_ user for that purpose. That user's name and password must also be stored in the `/db/www/poll/settings.xml` resource in the database, update them if you use your own user for that purpose.

The poll application may also define any user in a _poll_ group. Such users are configured to have access to the [http://localhost:8080/exist/projects/orders](http://localhost:8080/exist/projects/orders) page to see current orders status. The `scripts/bootstrap.sh` script creates a _poll_ user by default with `poll` password, you can change that password later on using eXist-DB administration tools.

To be done
----

Package as a XAR application to run directly from the database instead of the file system

Acknowledgments
---

Parts of this work are supported by the CoachCom2020 coordination and support action (H2020-635518) of the European Commission.

