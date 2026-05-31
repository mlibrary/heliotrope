# solrwrapper

Wrap any task with a Solr instance:

```ruby
SolrWrapper.wrap do |solr|
  # Something that requires Solr
end
```

Or with Solr and a solr collection:

```ruby
SolrWrapper.wrap do |solr|
  solr.with_collection(dir: File.join(FIXTURES_DIR, "basic_configs")) do |collection_name|
  end
end
```

## Basic Options

```ruby
SolrWrapper.wrap port: 8983,
                 verbose: true,
                 managed: true,
                 instance_dir: '/opt/solr'
```

### Valid ruby and YAML options

|Option         |                                         |
|---------------|-----------------------------------------|
| instance_dir  | Directory to store the solr index files |
| url           | URL of the Zip file to download |
| mirror_url    | Mirror to download the solr artifacts from (e.g. http://lib-solr-mirror.princeton.edu/dist/)|
| version       | Solr version to download and install |
| port          | port to run Solr on |
| version_file  | Local path to store the currently installed version |
| download_dir  | Local path for storing the downloaded Solr zip file |
| solr_zip_path | Local path to the Solr zip file |
| checksum      | Path/URL to checksum |
| solr_xml      | Path to Solr configuration |
| verbose       | (Boolean) |
| managed       | (Boolean) |
| ignore_checksum | (Boolean) |
| solr_options  | (Hash) |
| env           | (Hash) |
| persist      | (Boolean) Preserves the data in you collection between startups |

```ruby
solr.with_collection(name: 'collection_name', dir: 'path_to_solr_configs')
```

## From the command line

```console
$ solr_wrapper -p 8983
```
To see a list of valid options when using solr_wrapper to launch a Solr instance from the command line:
```
$ solr_wrapper -h
```

### Configuration file
SolrWrapper can read configuration options from a YAML configuration file.
By default, it looks for configuration files at `.solr_wrapper` and `~/.solr_wrapper`.

You can also specify a configuration file when launching from the command line as follows:
```
$ solr_wrapper --config <path_to_config_file>
```

### Cleaning your repository from the command line

By defualt SorlWrapper will clean out your data when it shuts down.
If you utilize the preserve option your data will remain between runs.

To clean out data that is being preserved explicitly run:
```
$ solr_wrapper <configuration options> clean
```
***Note*** You must use the same configuration options on the clean command as you do on the run command to clean the correct instance.

## Rake tasks

SolrWrapper provides rake tasks for installing, starting and stopping solr.  To include the tasks in your Rake environment, add this to your Rakefile

```ruby
  require 'solr_wrapper/rake_task'
```

You can configure the tasks by setting `SolrWrapper.default_instance_options`.  For example:

```ruby
SolrWrapper.default_instance_options = {
    verbose: true,
    cloud: true,
    port: '8888',
    version: '5.3.1',
    instance_dir: 'solr',
    download_dir: 'tmp'
}
require 'solr_wrapper/rake_task'
```
