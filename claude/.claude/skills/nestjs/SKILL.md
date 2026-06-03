---
name: nestjs
description: Build, scaffold, and reason about NestJS (Node.js) backend projects — modules, providers/DI, controllers, pipes/guards/interceptors/filters, data layer (TypeORM/Prisma/Mongoose), config, validation, auth, and Jest unit/e2e tests. Trigger when working in a repo with `@nestjs/*` in package.json, a `nest-cli.json`, files using `@Module`/`@Controller`/`@Injectable`, or when the user asks to create, scaffold, debug, or test a NestJS API/microservice.
---

# NestJS

Targets **NestJS v11** (latest stable line; v11.1.x as of mid-2026). Verify the project's actual major before applying anything version-specific — read `package.json` `@nestjs/core` version first.

## Non-negotiable: verify upstream before version-specific code

NestJS APIs, decorators, and package names drift between majors. Before writing config, decorator options, or integration code you are not certain holds in the project's version:

1. Read the project's `@nestjs/core` version in `package.json`.
2. Fetch the matching official doc page. **`docs.nestjs.com` is a client-rendered SPA — plain WebFetch returns only the page title.** Use one of:
   - `WebSearch` scoped to the topic, then fetch the GitHub raw doc source if needed.
   - Fetch the doc markdown from the docs repo: `https://raw.githubusercontent.com/nestjs/docs.nestjs.com/master/content/<path>.md`.
   - `nest --help` / `nest g --help` in the project for the installed CLI's exact schematics.
3. Prefer the project's existing patterns over anything here when they conflict.

## v11 facts that bite

- **Node 20+ required.** Node 16/18 dropped.
- **Express v5 is the default** HTTP adapter (path-matching syntax changed; wildcard routes use `*splat`-style named wildcards, not bare `*`). Fastify adapter is **v5**.
- **Global-module middleware runs first**, regardless of import order in the dependency graph.
- Dynamic modules are deduped by **object reference**, not a generated hash.
- Default test runner is still **Jest**; the starter wires `jest` (unit) + a separate e2e config with `supertest`.

## CLI quick reference

```bash
npm i -g @nestjs/cli           # or: npx @nestjs/cli@latest
nest new <app> --package-manager npm   # scaffold project (alias: nest n)
nest generate <schematic> <name>       # alias: nest g
nest build
nest start                     # nest start --watch  (-w) for dev; --debug to attach
```

Common `nest g` schematics (alias): `module` (mo), `controller` (co), `service` (s), `resource` (res — generates module+controller+service+DTOs+entity with CRUD), `guard` (gu), `interceptor` (itc), `pipe` (pi), `filter` (f), `middleware` (mi), `gateway` (ga), `provider` (pr), `class` (cl). Add `--flat`, `--no-spec`, `--dry-run` as needed. `nest g resource users` is the fastest way to a CRUD slice.

## Workflow for a typical request

1. **Locate the seam.** Find the owning module (`*.module.ts`). New feature → new module imported into `AppModule` or a parent. Don't dump providers into `AppModule`.
2. **Scaffold with the CLI**, not hand-written files — keeps naming, spec files, and module wiring consistent.
3. **Wire DI explicitly.** Provider must be in the module's `providers`; to use it elsewhere, add to `exports` and `imports` the module. Don't reach across modules with relative imports of concrete classes.
4. **Validate input at the boundary** with DTOs + `class-validator` + a global `ValidationPipe` (`whitelist: true, transform: true`). Never trust request bodies.
5. **Test the touched unit.** Add/adjust the `.spec.ts`; run the project's test command before declaring done.

## Reference files (load on demand)

- `references/building-blocks.md` — modules, providers/DI scopes, controllers & routing, middleware, pipes, guards, interceptors, exception filters, lifecycle hooks, execution order.
- `references/data-integration.md` — `@nestjs/config`, validation/DTOs, TypeORM, Prisma, Mongoose, Passport/JWT auth.
- `references/testing.md` — `Test.createTestingModule`, mocking providers, e2e with `supertest`, run commands.

Read the relevant reference file when the task touches that area; don't preload all of them.

## Definition of done

- Feature lives in its own module, wired via `imports`/`exports` (no cross-module concrete imports).
- DTOs validated; global `ValidationPipe` present (or per-route).
- Spec file added/updated and the project's `test`/`test:e2e` passes for touched code.
- `nest build` (or `tsc --noEmit`) is clean.
- No secrets hardcoded — config via `@nestjs/config` + env.
