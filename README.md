# Proscenium - Modern Client-Side Tooling for Rails

Proscenium treats your client-side code as first class citizens of your Rails app, and assumes a
"fast by default" internet. It bundles your JS, JSX and CSS in real time, on demand, and with zero
configuration.

- Zero configuration.
- Fast real-time bundling and minification.
- NO JavaScript runtime - just the browser!
- Deep integration with Rails.
- No additional process or server - Just run Rails!
- Serve assets from anywhere within your Rails root (/app, /config, /lib, etc.).
- Automatically side load JS/CSS for your layouts and views.
- Import JS(X) and CSS from node_modules, URL, local (relative, absolute).
- Support for JSX.
- Import map on the server.
- CSS Modules.
- CSS mixins.

## ⚠️ EXPERIMENTAL SOFTWARE ⚠️

While my goal is to use Proscenium in production, I strongly recommended that you **DO NOT** use
this in production apps! Right now, this should only be used for development/testing.

## Installation

Add this line to your application's Gemfile, and you're good to go:

```ruby
gem 'proscenium'
```

## Client-Side Code Anywhere

Proscenium believes that your frontend code is just as important as your backend code, and is not an
afterthought - they should be first class citizens of your Rails app. So instead of throwing all
your JS and CSS into a "app/assets" directory, and manually loading them, put them wherever you
want within your app!

For example, if you have JS that is used by your `UsersController#index`, then put it in
`app/views/users/index.js`. Or if you have some CSS that is used by your entire application, put it
in `app/views/layouts/application.css` and load it alongside your layout. Maybe you have a few JS
utility functions, so put them in `lib/utils.js`.

Simply create your JS(X) and CSS anywhere you want, and they will be served by your Rails app.

Using the examples above...

- `app/views/users/index.js` => `https://yourapp.com/app/views/users/index.js`
- `app/views/layouts/application.css` => `https://yourapp.com/app/views/layouts/application.css`
- `lib/utils.js` => `https://yourapp.com/lib/utils.js`
- `config/properties.css` => `https://yourapp.com/config/properties.css`

## Importing

Proscenium supports importing JS and CSS from `node_modules`, URL, and local (relative, absolute).

Imports are assumed to be JS files, so there is no need to specify the file extesnion in such cases.
But you can if you like. All other file types must be specified using their full file name and
extension.

### URL Imports

Any import beginning with `http://` or `https://` will be fetched from the URL provided:

```js
import React from 'https://esm.sh/react`
```

```css
@import 'https://cdn.jsdelivr.net/npm/bootstrap@5.2.0/dist/css/bootstrap.min.css';
```

URL imports are cached, so that each import is only fetched once per server restart.

### Import from NPM (`node_modules`)

Bare imports (imports not beginning with `./`, `/`, `https://`, `http://`) are fully supported, and
will use your package manager of choice (eg, NPM, Yarn, pnpm) via the `package.json` file:

```js
import React from 'react`
```

### Local Imports

And of course you can import your own code, using relative or absolute paths (file extension is
optional):

```js /app/views/layouts/application.js
import utils from '/lib/utils'
```

```js /lib/utils.js
import constants from './constants'
```

## Import Map

[Import map](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script/type/importmap) for both JS and CSS is supported out of the box, and works with no regard to the browser being used. This is because the import map is parsed and resolved by Proscenium on the server. If you are not familiar with import maps, think of it as a way to define aliases.

Just create `config/import_map.json` and specify the imports you want to use. For example:

```json
{
  "imports": {
    "react": "https://esm.sh/react@18.2.0",
    "start": "/lib/start.js",
    "common": "/lib/common.css",
    "@radix-ui/colors/": "https://esm.sh/@radix-ui/colors@0.1.8/",
  }
}
```

Using the above import map, we can do...

```js
import { useCallback } from 'react'
import startHere from 'start'
import styles from 'common'
```

and for CSS...

```css
@import 'common';
@import '@radix-ui/colors/blue.css';
```

You can also write your import map in Javascript instead of JSON. So instead of `config/import_map.json`, create `config/import_map.js`, and define an anonymous function. This function accepts a single `environment` argument.

```js
env => ({
  imports: {
    react: env === 'development' ? 'https://esm.sh/react@18.2.0?dev' : 'https://esm.sh/react@18.2.0'
  }
})
```

### Aliasing

You can also use the import map to define aliases:

```json
{
  "imports": {
    "react": "preact/compact",
  }
}
```

## Side Loading

Proscenium has built in support for automatically side loading JS and CSS with your views and
layouts.

Just create a JS and/or CSS file with the same name as any view or layout, and make sure your
layouts include `<%= side_load_stylesheets %>` and `<%= side_load_javascripts %>`. Something like
this:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Hello World</title>
    <%= side_load_stylesheets %>
  </head>
  <body>
    <%= yield %>
    <%= side_load_javascripts defer: true, type: 'module' %>
  </body>
</html>
```

On each page request, Proscenium will check if your layout and view has a JS/CSS file of the same
name, and include them into your layout HTML. Partials are not side loaded.

Side loading is enabled by default, but you can disable it by setting `config.proscenium.side_load`
to `false`.

## CSS Modules

Give any CSS file a `.module.css` extension, and Proscenium will load it as a CSS Module...

```css
.header {
  background-color: #00f;
}
```

The above produces:

```css
.header5564cdbb {
  background-color: #00f;
}
```

Importing a CSS file from JS will automatically append the stylesheet to the document's head. And the results of the import will be an object of CSS class to module names.

```js
import styles from './styles.module.css'
// styles == { header: 'header5564cdbb' }
```

It is important to note that the exported object of CSS module names is actually a Proxy object. So destructuring the object will not work. Instead, you must access the properties directly.

Also, importing a CSS module from another CSS module will result in the same digest string for all classes.

## CSS Mixins

CSS mixins are supported using the `@define-mixin` and `@mixin` at-rules.

A mixin is defined using the `@define-mixin` at-rule. Pass it a name, which should adhere to class name semantics, and declare your rules:

```css
// /lib/mixins.css
@define-mixin bigText {
  font-size: 50px;
}
```

Use a mixin using the `@mixin` at-rule. Pass it the name of the mixin you want to use, and the url where the mixin is declared. The url is used to resolve the mixin, and can be relative, absolute, or a URL.

```css
// /app/views/layouts/application.css
p {
  @mixin bigText from url('/lib/mixins.css');
  color: red;
}
```

Mixins can be declared in any CSS file. They do not need to be declared in the same file as where they are used. If you declare and use a mixin in the same file, you don't need to specify the URL of where the mixin is declared.

```css
@define-mixin bigText {
  font-size: 50px;
}

p {
  @mixin bigText;
  color: red;
}
```

CSS modules and Mixins works perfectly together. You can include a mixin in a CSS module.

## Importing SVG from JS(X)

Importing SVG from JS(X) will bundle the SVG source code. Additionally, if importing from JSX, the SVG source code will be rendered as a JSX component.

*docs needed*

## Environment Variables

Import any environment variables from your Rails app into your JS(X) code.

```js
import RAILS_ENV from '@proscenium/env/RAILS_ENV'
```

*docs needed*

## Importing i18n

Basic support is provided for importing your Rails locale files.

```js
import translations from '@proscenium/i18n'
```

*docs needed*

## Phlex Support

*docs needed*

## ViewComponent Support

*docs needed*

## Cache Busting [WIP]

By default, all assets are not cached by the browser. But if in production, you populate the `REVISION` env variable, all CSS and JS URL's will be appended with its value as a query string, and the `Cache-Control` response header will be set to `public` and a max-age of 30 days.

For example, if you set `REVISION=v1`, URL's will be appended with `?v1`: `/my/imported/file.js?v1`.

It is assumed that the `REVISION` env var will be unique between deploys. If it isn't, then assets will continue to be cached as the same version between deploys. I recommend you assign a version number or to use the Git commit hash of the deploy. Just make sure it is unique for each deploy.

You can set the `cache_query_string` config option directly to define any query string you wish:

```ruby
Rails.application.config.proscenium.cache_query_string = 'my-cache-busting-version-string'
```

The cache is set with a `max-age` of 30 days. You can customise this with the `cache_max_age` config option:

```ruby
Rails.application.config.proscenium.cache_max_age = 12.months.to_i
```

## Include Paths

By default, Proscenium will serve files ending with any of these extension: `js,mjs,css,jsx`, and only from `config`, `app/views`, `lib` and `node_modules` directories.

However, you can customise these paths with the `include_path` config option...

```ruby
Rails.application.config.proscenium.include_paths << 'app/components'
```

## rjs is back!

Proscenium brings back RJS! Any path ending in .rjs will be served from your Rails app. This allows you to import server rendered javascript.

## Serving from Ruby Gem

*docs needed*

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Running Go benchmarks

```bash
go test ./internal/builder -bench=. -run="^$" -count=10 -benchmem
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joelmoss/proscenium. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/joelmoss/proscenium/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Proscenium project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/joelmoss/proscenium/blob/master/CODE_OF_CONDUCT.md).
