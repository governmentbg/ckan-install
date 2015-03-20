This will setup CKAN 2.2 with:
- file storage enabled
- datastore extension
- datapusher extensions
- obshtestvo theme extention

Currently, the provided setup script is for **debian machines only**.

## Usage

1. Download git submodules: `git submodule update --init`
1. Setup config. Start with template: `cp config.sh.sample config.sh` and modify the `config.sh` to your needs.

Whatever password you set for postgres users make sure you type the same in the installation
1. Run install: `bash debian/init.sh`

After install you might want to:

1. Add additional server aliases at `/etc/apache2/sites-available/$CKAN_INSTANCE_NAME`
1. Disable user registrations by running `bash disable_user_registrations.sh`


## Further notes
This project is developed following CKAN install guides. If something's missing in the guide, then the project might be
missing the same thing.

If using CKAN 2.2 or lower consider upgrading to CKAN 2.3 or later, because of resource_proxy:

>As resource views are rendered on the browser, if the file they are accessing is located in a different 
>domain than the one CKAN is hosted, the browser will block access to it because of the same-origin policy. For instance, 
>files hosted on www.example.com won’t be able to be accessed from the browser if CKAN is hosted on data.catalog.com.
>
>To allow view plugins access to external files you need to activate the resource_proxy plugin on your configuration file:
>
>```
>ckan.resource_proxy.max_file_size
>```
>
>ref:
> 
> - http://docs.ckan.org/en/latest/maintaining/data-viewer.html?highlight=recline_view#resource-proxy
> - http://docs.ckan.org/en/latest/maintaining/data-viewer.html?highlight=recline_view#migrating-from-previous-ckan-versions