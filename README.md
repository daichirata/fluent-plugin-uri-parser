# fluent-plugin-uri-parser

[![Gem Version](https://badge.fury.io/rb/fluent-plugin-uri-parser.svg)](https://badge.fury.io/rb/fluent-plugin-uri-parser)
[![test](https://github.com/daichirata/fluent-plugin-uri-parser/actions/workflows/test.yml/badge.svg)](https://github.com/daichirata/fluent-plugin-uri-parser/actions/workflows/test.yml)

Fluentd filter plugins that **decompose URIs and query strings into structured fields**, so you can search, group, and aggregate on them in your downstream stack.

```text
"https://example.com:8080/search?q=fluentd&lang=ja"
                                ↓
{ scheme: "https", host: "example.com", port: 8080,
  path: "/search", query: "q=fluentd&lang=ja", fragment: nil }
```

## Why?

URL strings sitting in a single log field are a black box — you can't filter by host, group by path, or count by query parameter without parsing them first. These filters turn a raw URL into a record your storage can index.

| Plugin | Turns this | Into this |
|---|---|---|
| `uri_parser` | `https://example.com:8080/p?q=1#x` | `scheme`, `host`, `port`, `path`, `query`, `fragment` |
| `query_string_parser` | `foo=bar&hoge=fuga` | `{ "foo" => "bar", "hoge" => "fuga" }` |

## Requirements

| fluent-plugin-uri-parser | fluentd     | ruby   |
| ------------------------ | ----------- | ------ |
| >= 0.4.0                 | >= v1.0.0   | >= 3.2 |
| >= 0.3.0                 | >= v0.14.0  | >= 2.1 |
|  < 0.2.0                 | >= v0.12.0  | >= 1.9 |

## Installation

```shell
gem install fluent-plugin-uri-parser
```

Or in your `Gemfile`:

```ruby
gem "fluent-plugin-uri-parser"
```

---

## `uri_parser`

Decomposes a URI field into its components.

### Minimal example

```aconf
<filter access.log>
  @type uri_parser
  key_name url
  out_key_scheme   scheme
  out_key_host     host
  out_key_port     port
  out_key_path     path
  out_key_query    query
  out_key_fragment fragment
</filter>
```

```jsonc
// input
{ "url": "https://example.com:8080/search?q=fluentd#top" }

// output
{
  "url":      "https://example.com:8080/search?q=fluentd#top",
  "scheme":   "https",
  "host":     "example.com",
  "port":     8080,
  "path":     "/search",
  "query":    "q=fluentd",
  "fragment": "top"
}
```

> The `port` value uses [`Addressable::URI#inferred_port`](https://github.com/sporkmonger/addressable), so well-known schemes (`http` → 80, `https` → 443, ...) get a port even when the URL omits one.

### Group output under a single key — `hash_value_field`

```aconf
<filter access.log>
  @type uri_parser
  key_name url
  hash_value_field parsed
  out_key_host host
  out_key_path path
</filter>
```

```jsonc
// input
{ "url": "https://example.com/search" }

// output
{
  "url": "https://example.com/search",
  "parsed": { "host": "example.com", "path": "/search" }
}
```

### Namespace output keys — `inject_key_prefix`

```aconf
<filter access.log>
  @type uri_parser
  key_name url
  inject_key_prefix url.
  out_key_host host
  out_key_path path
</filter>
```

```jsonc
// input
{ "url": "https://example.com/search" }

// output
{
  "url":      "https://example.com/search",
  "url.host": "example.com",
  "url.path": "/search"
}
```

### Drop empty components — `ignore_nil`

When a component is missing (no query, no fragment, etc.) the default is to emit it as `null`. Set `ignore_nil true` to omit those keys entirely.

```jsonc
// input
{ "url": "https://example.com/path" }

// ignore_nil false  (default)
{ "scheme": "https", "host": "example.com", "port": 443,
  "path": "/path", "query": null, "fragment": null }

// ignore_nil true
{ "scheme": "https", "host": "example.com", "port": 443,
  "path": "/path" }
```

---

## `query_string_parser`

Decomposes a query string field into individual parameters.

### Minimal example

```aconf
<filter access.log>
  @type query_string_parser
  key_name query
</filter>
```

```jsonc
// input
{ "query": "foo=bar&hoge=fuga" }

// output
{ "query": "foo=bar&hoge=fuga", "foo": "bar", "hoge": "fuga" }
```

### Group output under a single key — `hash_value_field`

```aconf
<filter access.log>
  @type query_string_parser
  key_name query
  hash_value_field params
</filter>
```

```jsonc
// input
{ "query": "foo=bar&hoge=fuga" }

// output
{
  "query":  "foo=bar&hoge=fuga",
  "params": { "foo": "bar", "hoge": "fuga" }
}
```

### Handle repeated parameters

A request like `?tag=ruby&tag=fluentd` has two `tag` values. By default the last one wins (scalar). You have two ways to keep both:

#### Option A: always arrays — `multi_value_params true`

Every parameter becomes an array, even when it appeared once.

```jsonc
// input
{ "query": "tag=ruby&tag=fluentd&lang=ja" }

// output
{ "tag": ["ruby", "fluentd"], "lang": ["ja"] }
```

#### Option B: array only for listed names — `multi_value_param_names`

You know `tag` may repeat but `lang` won't. Keep `lang` as a scalar and only wrap `tag` in an array.

```aconf
<filter access.log>
  @type query_string_parser
  key_name query
  multi_value_param_names tag
</filter>
```

```jsonc
// input
{ "query": "tag=ruby&tag=fluentd&lang=ja" }

// output
{ "tag": ["ruby", "fluentd"], "lang": "ja" }
```

> When both are set, `multi_value_params true` wins.

---

## Options

Shared between both filters unless noted.

| Option | Type | Default | What it does |
| --- | --- | --- | --- |
| `key_name` | string | — *(required)* | Record key holding the URL or query string to parse. |
| `hash_value_field` | string | `nil` | If set, all extracted fields are nested under this key. |
| `inject_key_prefix` | string | `nil` | Prefix prepended to every extracted key. |
| `ignore_key_not_exist` | bool | `false` | When `key_name` is missing, drop the record instead of passing it through. |
| `emit_invalid_record_to_error` | bool | `true` | When `key_name` is missing, emit the record to Fluentd's error stream. |
| `suppress_parse_error_log` | bool | `false` | Silence the warning log when the value fails to parse. |
| `ignore_nil` | bool | `false` | *(uri_parser only)* Omit output keys whose parsed value is `nil`. |
| `out_key_scheme` / `out_key_host` / `out_key_port` / `out_key_path` / `out_key_query` / `out_key_fragment` | string | `nil` | *(uri_parser only)* Output key name for each URI component. Components without an `out_key_*` are not emitted. |
| `multi_value_params` | bool | `false` | *(query_string_parser only)* Emit every parameter as an array. |
| `multi_value_param_names` | array | `nil` | *(query_string_parser only)* Emit only the listed parameters as arrays. Ignored when `multi_value_params` is `true`. |

---

## Development

```shell
bundle install
bundle exec rake test
```

To install this gem onto your local machine: `bundle exec rake install`.
To release: bump the version in the gemspec, then `bundle exec rake release` (tags, pushes, and uploads to [rubygems.org](https://rubygems.org)).

## Contributing

Bug reports and pull requests are welcome at <https://github.com/daichirata/fluent-plugin-uri-parser>.

## License

Apache-2.0
