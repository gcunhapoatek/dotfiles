# Core building blocks

NestJS v11. Verify decorator options against the installed version when uncertain.

## Modules

A module groups a cohesive feature. Decorate a class with `@Module({ imports, controllers, providers, exports })`.

```ts
@Module({
  imports: [TypeOrmModule.forFeature([User])], // other modules whose exports this module needs
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService], // make available to modules that import this one
})
export class UsersModule {}
```

Rules:
- A provider is only injectable inside its module unless `exports`ed and the consumer `imports` the module.
- `AppModule` is the root; keep it thin — it mostly `imports` feature modules.
- **Dynamic modules** (`forRoot`/`forRootAsync`/`forFeature`) configure a module at import time. Use `forRootAsync` to inject config. Mark cross-cutting modules `@Global()` sparingly (config, db) — global overuse hides coupling.

## Providers & dependency injection

`@Injectable()` marks a class for the DI container. Inject via constructor:

```ts
constructor(private readonly users: UsersService) {}
```

Provider registration forms in `providers`:
- `UsersService` — shorthand for `{ provide: UsersService, useClass: UsersService }`.
- `{ provide: 'TOKEN', useValue: ... }` — constants; inject with `@Inject('TOKEN')`.
- `{ provide: X, useClass: Y }` — swap implementation.
- `{ provide: X, useFactory: (dep) => ..., inject: [Dep] }` — computed providers (async supported).

**Injection scopes** (`@Injectable({ scope: Scope.* })`):
- `DEFAULT` (singleton) — almost always correct.
- `REQUEST` — new instance per request; needed for per-request state, but bubbles up the chain (consumers become request-scoped too) and costs performance. Use only when required.
- `TRANSIENT` — new instance per consumer.

Prefer constructor injection over `moduleRef.get()`; use `ModuleRef` only for dynamic resolution.

## Controllers & routing

```ts
@Controller('users')
export class UsersController {
  @Get()            findAll(@Query() q: ListUsersDto) {}
  @Get(':id')       findOne(@Param('id') id: string) {}
  @Post()           create(@Body() dto: CreateUserDto) {}
  @Patch(':id')     update(@Param('id') id: string, @Body() dto: UpdateUserDto) {}
  @Delete(':id')    remove(@Param('id') id: string) {}
}
```

- Param decorators: `@Body`, `@Param`, `@Query`, `@Headers`, `@Req`/`@Res` (avoid `@Res` unless you need raw response control — it disables Nest's serialization).
- Status: `@HttpCode(204)`; headers: `@Header()`; redirect: `@Redirect()`.
- **Express v5 routing**: bare `*` wildcards no longer valid — use named wildcards like `@Get('files/*splat')`. Verify against the project's adapter.
- Return value is serialized to JSON automatically; return entities/DTOs, not the raw response object.

## Request lifecycle / execution order

For an incoming request the order is:

1. **Middleware** (global → module-bound). Express-style `(req, res, next)`. Registered in a module's `configure(consumer)` (module implements `NestModule`). v11: global-module middleware always runs first.
2. **Guards** — auth: return boolean/throw. Implement `CanActivate`. Run after middleware, before interceptors.
3. **Interceptors (pre)** — wrap the handler; can transform request/response, add timing, caching. Implement `NestInterceptor`, return via RxJS `next.handle().pipe(...)`.
4. **Pipes** — transform/validate the bound args (`ValidationPipe`, `ParseIntPipe`, custom).
5. **Route handler**.
6. **Interceptors (post)** — map/catch the response stream.
7. **Exception filters** — catch thrown errors, shape the response.

Bind any of these at method / controller / global scope. Global binding for DI-aware instances: register as `APP_GUARD` / `APP_INTERCEPTOR` / `APP_PIPE` / `APP_FILTER` providers instead of `app.useGlobal*()` when they need injection.

```ts
{ provide: APP_GUARD, useClass: AuthGuard }
```

## Pipes

Validate or transform method args. Built-ins: `ValidationPipe`, `ParseIntPipe`, `ParseUUIDPipe`, `ParseArrayPipe`, `DefaultValuePipe`. See `data-integration.md` for `ValidationPipe` + DTO setup.

## Guards

```ts
@Injectable()
export class RolesGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest();
    return /* check req.user / roles */;
  }
}
```
Read metadata set by custom decorators via `Reflector`. Throw `ForbiddenException` to reject with a clear status.

## Interceptors

```ts
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  intercept(ctx: ExecutionContext, next: CallHandler): Observable<any> {
    const start = Date.now();
    return next.handle().pipe(tap(() => console.log(`+${Date.now() - start}ms`)));
  }
}
```
Uses: response shaping (`ClassSerializerInterceptor`), timeouts, caching, transactions.

## Exception filters

Nest maps `HttpException` subclasses (`NotFoundException`, `BadRequestException`, …) to status codes automatically. Throw those from services. Add a custom `@Catch()` filter only when you need a non-default error shape or to catch non-HTTP errors. Keep filters thin; don't swallow the original error context.

## Lifecycle hooks

`OnModuleInit`, `OnApplicationBootstrap`, `OnModuleDestroy`, `OnApplicationShutdown` (the last needs `app.enableShutdownHooks()`). Use for warming caches, opening/closing external connections.
