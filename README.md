# Attachments

[![Build Status](https://secure.travis-ci.org/mrkamel/attachments.png?branch=master)](http://travis-ci.org/mrkamel/attachments)

Declarative and flexible attachments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'attachments'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install attachments

## Usage

First, `include Attachments` and specify an attachment:

```ruby
class User
  include Attachments

  attachment :avatar, versions: {
    icon: { path: "users/:id/avatar/icon.jpg" },
    thumbnail: { path: "users/:id/avatar/thumbnail.jpg" },
    original: { path: "users/:id/avatar/original.jpg" }
  }
end
```

Second, store blobs for your version:

```ruby
user.avatar(:icon).store("blob")
user.avatar(:thumbnail).store("blob")
user.avatar(:original).store("blob")
```

or via multipart upload

```ruby
user.avatar(:icon).store_multipart do |upload|
  upload.upload_part "chunk1"
  upload.upload_part "chunk2"
  # ...
end
```

Third, add the images url to your views:

```
image_tag user.avatar(:thumbnail).url
```

More methods to manipulate the blobs:

```ruby
user.avatar(:icon).delete
user.avatar(:icon).exists?
user.avatar(:icon).value
user.avatar(:icon).temp_url(expires_in: 2.days) # Must be supported by the driver
```

## Drivers

The `attachments` gem ships with the following drivers:

* `Attachments::FileDriver`: To store files on the local file system
* `Attachments::FakeDriver`: To store files in memory (for testing)
* `Attachments::S3Driver`: To store files on S3
* `Attachments::SwiftDriver`: To store files on an Openstack Swift provider

You can eg use the file system driver:

```ruby
require "attachments/file_driver"

Attachments.default_options[:driver] = Attachment::FileDriver.new("/path/to/attachments")

class User
  include Attachments

  attachment :avatar, host: "www.example.com", versions: {
    # ...
  }
end
```

## Contributing

1. Fork it ( https://github.com/mrkamel/attachments/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
