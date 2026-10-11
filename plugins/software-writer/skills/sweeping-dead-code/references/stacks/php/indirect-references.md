# PHP: References a name search misses

A plain-name search misses or misattributes these references. Check them before concluding that a symbol has no production caller; references from test files do not count as callers.

- `__call` and `__callStatic` receive calls to inaccessible or non-existent methods; `__invoke` runs when an object is called as a function (`$obj(...)`).
- Variable and string callables carry the name as data: `$obj->$name()`, `$fn()`, `[$obj, 'method']`, `'Class::method'`, `call_user_func(...)`.
- `use Foo\Bar as Baz` puts `Baz` at every call site. Aliases do not apply to class names held in strings, which carry the runtime-resolvable name, typically the FQCN.
- The Symfony container registers services by `resource:` directory glob, autowires them by constructor type-hint, and tags them by implemented interface or attribute (`#[AsEventListener]`, `#[AsCommand]`, `#[AsMessageHandler]`). `getSubscribedEvents()` names handler methods as strings, and `#[AsEventListener]` without `method:` calls `on` + the PascalCased event name, or `__invoke()` when that method does not exist or no `event:` is given.
- Symfony routes reach controller methods through `#[Route]` attributes and YAML `controller: App\Controller\Foo::bar` strings.
- Twig `obj.name` resolves to an array key, a property, then a method `name()`, `getName()`, `isName()`, or `hasName()`.
- Composer `autoload.files` load whenever the autoloader loads, with no reference from code; `composer.json` `scripts` reference static methods as `Class::method` strings.
- Doctrine XML mapping names entity classes and fields as strings.
