# Data & integration

NestJS v11. Confirm package majors in `package.json` before applying config — ORM/auth packages drift fast.

## Configuration — `@nestjs/config`

```bash
npm i @nestjs/config
```

```ts
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,            // inject ConfigService anywhere without re-importing
      envFilePath: ['.env.local', '.env'],
      validationSchema: envSchema, // Joi or custom validate fn — fail fast on bad env
    }),
  ],
})
export class AppModule {}
```

Inject: `constructor(private config: ConfigService) {}` → `config.getOrThrow<string>('DATABASE_URL')`. Prefer `getOrThrow` for required vars so boot fails loudly. Never read `process.env` directly outside config setup. Keep secrets in `.env*` (gitignored), not the repo.

## Validation — DTOs + `class-validator`

```bash
npm i class-validator class-transformer
```

```ts
// create-user.dto.ts
export class CreateUserDto {
  @IsEmail() email: string;
  @IsString() @MinLength(8) password: string;
  @IsOptional() @IsInt() age?: number;
}
```

Enable globally in `main.ts`:

```ts
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,            // strip properties not in the DTO
  forbidNonWhitelisted: true, // 400 on unknown properties
  transform: true,            // instantiate the DTO class + coerce primitives
  transformOptions: { enableImplicitConversion: true },
}));
```

- `whitelist` + `forbidNonWhitelisted` is the safe default — rejects mass-assignment.
- For nested objects use `@ValidateNested()` + `@Type(() => Child)` (class-transformer).
- `PartialType(CreateUserDto)` (from `@nestjs/mapped-types` or `@nestjs/swagger`) for update DTOs.

## TypeORM — `@nestjs/typeorm`

```bash
npm i @nestjs/typeorm typeorm pg   # driver per db (pg, mysql2, better-sqlite3…)
```

```ts
TypeOrmModule.forRootAsync({
  imports: [ConfigModule],
  inject: [ConfigService],
  useFactory: (c: ConfigService) => ({
    type: 'postgres',
    url: c.getOrThrow('DATABASE_URL'),
    autoLoadEntities: true,
    synchronize: false,        // NEVER true outside throwaway dev — use migrations
  }),
})
```

Per-feature: `TypeOrmModule.forFeature([User])` in the feature module; inject with `@InjectRepository(User) private repo: Repository<User>`. Use migrations (`typeorm migration:generate/run`) for schema changes — `synchronize: true` drops/alters data.

## Prisma

No first-party Nest module — wrap the client in an injectable service:

```ts
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() { await this.$connect(); }
}
```
Export it from a `PrismaModule` (often `@Global()`); inject `PrismaService` into feature services. Schema lives in `prisma/schema.prisma`; run `prisma migrate dev` / `prisma generate`.

## Mongoose — `@nestjs/mongoose`

```bash
npm i @nestjs/mongoose mongoose
```

```ts
MongooseModule.forRootAsync({ /* useFactory → { uri } */ });
// feature:
MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]);
```
Define schemas with `@Schema()` / `@Prop()` decorators; inject `@InjectModel(User.name) private model: Model<User>`.

## Auth — Passport + JWT

```bash
npm i @nestjs/passport passport @nestjs/jwt passport-jwt
npm i -D @types/passport-jwt
```

Pattern:
1. `JwtModule.registerAsync` with secret + `signOptions.expiresIn` from config.
2. `AuthService.validateUser` checks credentials (hash with `argon2`/`bcrypt` — never store plaintext); `login` returns `{ access_token: jwt.sign(payload) }`.
3. `JwtStrategy extends PassportStrategy(Strategy)` — extract bearer token, set `validate(payload)` → returns the user attached to `req.user`.
4. Protect routes with a guard: `@UseGuards(AuthGuard('jwt'))`, or register `APP_GUARD` for global auth + a `@Public()` metadata escape hatch.

Keep the JWT secret in config/env. Set a sane `expiresIn`; use refresh tokens for long sessions. Hash passwords; compare with constant-time verify.
