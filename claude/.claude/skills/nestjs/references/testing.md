# Testing

NestJS v11 starter uses **Jest**. Confirm the project's `package.json` scripts — some teams swap in Vitest; match what's there.

## Commands (default starter scripts)

```bash
npm run test          # jest — unit specs (*.spec.ts)
npm run test:watch
npm run test:cov      # coverage
npm run test:e2e      # jest -c test/jest-e2e.json — *.e2e-spec.ts
```

Unit specs sit next to source (`users.service.spec.ts`); e2e specs live in `test/` with their own Jest config.

## Unit test — `Test.createTestingModule`

Build a minimal module with the unit under test and **mocked** dependencies — don't pull in the real DB.

```ts
describe('UsersService', () => {
  let service: UsersService;
  const repo = { find: jest.fn(), save: jest.fn() };

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getRepositoryToken(User), useValue: repo }, // override TypeORM repo
      ],
    }).compile();
    service = module.get(UsersService);
  });

  it('returns all users', async () => {
    repo.find.mockResolvedValue([{ id: '1' }]);
    expect(await service.findAll()).toHaveLength(1);
  });
});
```

- Override any provider by matching its token: `{ provide: Token, useValue: mock }`.
- For DI tokens use the right helper: `getRepositoryToken(Entity)` (TypeORM), `getModelToken(Name)` (Mongoose), or the literal string/class token.
- `.overrideProvider(X).useValue(...)` is an alternative to listing providers when testing a real module.
- Reset mocks between tests (`jest.clearAllMocks()` in `afterEach`, or `clearMocks: true` in Jest config).

## Controller test

Same pattern: include the controller, mock the service. Assert the controller delegates and shapes output — don't re-test service logic.

## e2e test — `supertest`

Boots the full Nest app over HTTP. Apply the same global pipes/guards as `main.ts` so behavior matches production.

```ts
describe('Users (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });

  afterAll(async () => { await app.close(); });

  it('POST /users validates body', () =>
    request(app.getHttpServer())
      .post('/users')
      .send({ email: 'bad' })
      .expect(400));
});
```

- `request(app.getHttpServer())` — pass the underlying server, not the Nest app.
- Always `await app.close()` in `afterAll` to release ports/connections.
- For DB-backed e2e, point at a disposable test database (testcontainers / a separate `.env.test`); never run against real data.
- Override external services with `.overrideProvider()` to keep e2e deterministic.

## What to assert

- Service: business logic + branch coverage with mocked I/O.
- Controller: routing/delegation + DTO binding.
- e2e: status codes, validation rejection, auth gating, response shape on the happy path.

Add a failing test first when fixing a bug, then make it pass.
