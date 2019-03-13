# Test Certs

Gives you a browser installable certificate authority for testing purposes.

Your personal certificate authority can easily issue browser compatible certificates for any domain.

This allows you to get green padlocks on test domains during application development, making non-public integration testing easier.

## Instructions

Create or update the Certificate Authority's root/intermediate certificates.

```
bin/authority some-org-name
```

Issue a terminal (browser) cert for a specific domain.

```
bin/issue some-org-name domain.com.test
```

Install the built certificate authority in your browser.

```
build/some-org-name/ca.crt
```

Install the domain certs in your application's web server.

```
build/some-org-name/domain.com.test.crt
build/some-org-name/domain.com.test.key
```
