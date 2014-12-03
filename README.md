<pre>
    )                          )          )
 ( /(        (       *   )  ( /(       ( /(
 )\()) (     )\    ` )  /(  )\()) (    )\())
((_)\  )\ ((((_)(   ( )(_))((_)\  )\  ((_)\
 _((_)((_) )\ _ )\ (_(_())  _((_)((_)  _((_)
| || || __|(_)_\(_)|_   _| | || || __|| \| |
| __ || _|  / _ \    | |   | __ || _| | .` |
|_||_||___|/_/ \_\   |_|   |_||_||___||_|\_|
</pre>
# Convert the heathens. 

Heathen is a service for converting pretty much anything to PDF, where "anything" means:

* Word documents
* HTML documents
* Images
* HTML/Images found at a URL
    
Additionally, given an image as input, Heathen can parse text found in the image and generate a PDF that is searchable and has selectable text.

There is a client gem [here](https://github.com/ifad/heathen-client): https://github.com/ifad/heathen-client.

Heathen is built primarily with [Sinatra](http://www.sinatrarb.com/) and [Dragonfly](http://markevans.github.com/dragonfly/).

## Why
Why you might want to use Heathen:

* Word is evil and must be purified.
* You are writing a web application (or many web applications) that need to be able to produce PDFs. With Heathen, you just write your document as a normal HTML document and send it off to Heathen to get a PDF.
* You are an organization that has many scanned documents stored as images that are therefore not searchable or indexable. Send them off to Heathen and get searchable, selectable PDFs.
    
## Installation & Prerequisites

Heathen requires the following libraries/binaries to be installed, and the versions given are those with which Heathen has been tested:

* LibreOffice + PyUNO (3.6)
* Python              (2.7)
* ImageMagick         (6.8.2-4)
* wkhtmltopdf         (0.9.6)
* tesseract           (3.02.02)
* redis               (2.4.15)
    
To install, clone this repository:

`git clone git@github.com:ifad/heathen.git`

Then bundle:

`bundle`

If you're using OpenSuSE, we maintain all these binary dependences as RPM packages [on the SuSE build server](https://build.opensuse.org/project/show?project=home%3Avjt:ifad), so they are just a `zypper ar` and a `zypper install` away.

## Running

You need to specify where Heathen will store files by setting the `HEATHEN_STORAGE_ROOT` environment variable. Heathen creates three subdirectories at this path: `cache`, `file`, and `tmp`.

* With rackup:

    `HEATHEN_STORAGE_ROOT="/path/to/storage" rackup -E <environment>`
    
* With [pow](http://pow.cx/):
    
    Add the following to your .powenv file:
    ```
    export HEATHEN_STORAGE_ROOT="/path/to/storage"
    export RACK_ENV="<environment>"
    ```

Additionally, if you plan on running Heathen at a subdirectory, for example, `http://my.webapps.example.com/heathen`, you will need to set `RACK_RELATIVE_URL_ROOT="/heathen"`

**NOTE**: For Word/Excel conversion, heathen needs a LibreOffice/OpenOffice daemon running, listening on `localhost` on TCP port `8100`. This is the command we use to start it (make sure `libreoffice-pyuno` is installed):

```
soffice --headless --accept='socket,host=127.0.0.1,port=8100;urp;'
```

**NOTE**: If you are running Heathen behind [Unicorn](http://unicorn.bogomips.org/) or something similar, you will need to increase the allowed response time to be much greater than 30 seconds. There are plans to make Heathen behave asynchronously in the future which should avoid the need for this kind of configuration.

## Use It
While Heathen is meant to be used as an API (see https://github.com/ifad/heathen-client), it also has a minimal front-end.

Navigate to the app, select a word document to upload, and select `pdf` from the `Action` select box. Submit the form and if everything goes well, you will see some JSON data containing two urls, keyed by `original` and `converted`. Navigate to the `converted` url and wait for the browser to ask where you want to save your pdf.

Now upload an image containing some text, like a scanned document. Follow the same steps, and note that your pdf has selectable text and is searchable.

Re-visit the `converted` url and note that the response is immediate.

## How It Works
Heathen makes extensive use of the absolutely wonderful [Dragonfly](http://markevans.github.com/dragonfly/), and packages everything up as a micro-application with [Sinatra](http://www.sinatrarb.com/).

You give Heathen some content (either a file or URL) and an action by POSTing to /convert. Heathen does a minimal amount of checking to make sure the request is sane and that the supplied content will (probably) be processable, puts the file in permanent storage, and gives you back two links, but does no actual processing.

The `original` url simply points to the unaltered content that was originally uploaded.

The `converted` url is actually serialized information that Dragonfly uses to kick-off the processing steps. Visiting this link will convert the original content to pdf, which is why visiting the link the first time can take a long time. However, since Heathen also uses [Rack::Cache](https://github.com/rtomayko/rack-cache), the processed content is placed in the cache and never needs to be processed again.

If you want content to be re-processed the next time it is requested, you can run `rake heathen:cache:clear`.

Additionally, when content is sent to Heathen, a hash is computed which acts as a key to the processed content. That is, if you upload some content that Heathen has already seen (even if the filename is different), you will get back the exact same response as the first time, meaning that if the content is already cached, GETting the `converted` url will respond immediately.

To remove these mappings, you can run `rake heathen:redis:clear`.

For convenience, to clear both redis and the cache, plus any residual temp files that may not have been cleaned up by Heathen, you can run `rake heathen:clear`.

## AutoHeathen
AutoHeathen is a utility to allow people to email the documents they want converted to Heathen, which then converts them and either returns the converted documents to sender, or forwards them on to a configured email address. The general idea is that bin/autoheathen will be called by a mail forwarding script, which pipes the email into $stdin.

As an example for configuration, here is how we did it with postfix:

1. Postfix relay

/etc/postfix/aliases:

  heathen.rts: :include:/app/heathen/current/config/heathen.rts

(remember to run sudo postalias /etc/postfix/aliases afterwards)
 
2. Forwarding script

/app/heathen/current/config/heathen.rts:

  |"(cd /app/heathen/current; /home/heathen/.rbenv/bin/rbenv exec bundle exec bin/autoheathen -r -C config/autoheathen.yml>> log/autoheathen.log 2>&1)"

3. Config

Edit autoheathen.yml to suit the location of your heathen app (possibly via a reverse proxy like nginx if the unicorns are listening on a domain socket rather than TCP/IP).

## CVHeathen
This is a utility to convert a directory full of files. The script walks the entire directory tree and converts the files it finds, writing the result to the equivalent position in a new directory. The script also handles email files (.msg and .eml suffixes). For these, attachments are converted and saved in the form {filename}.{attachment name} where filename is the original email file name with suffix removed, and attachment name is the converted attachment file name.

  bin/cvheathen [-v] -i {in-dir} -o {out-dir}

  # -v = verbose

In order to convert .msg files to a readable form, the utility uses a Perl library (Email::Outlook::Message). To install the appropriate Debian packages, run:

  sudo apt-get install libemail-outlook-message-perl libemail-sender-perl

## License
MIT

## Copyright
&copy; IFAD 2013


