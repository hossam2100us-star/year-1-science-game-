import { z } from 'zod';

/**
 * Request schemas. They mirror `api/openapi.yaml` (the contract tests check
 * real responses against that file) and the app's own rules, e.g. the child
 * name rule is the same as `lib/core/validation.dart`.
 */
export const Uuid = z
  .string()
  .regex(
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
    'must be a lower-case UUID',
  );

export const Email = z
  .string()
  .trim()
  .min(3)
  .max(254)
  .pipe(z.email())
  .transform((e) => e.toLowerCase());

/** Length in Unicode code points, after NFKC normalisation. */
export const Password = z
  .string()
  .max(512)
  .transform((p) => p.normalize('NFKC'))
  .refine((p) => [...p].length >= 12, { message: 'must be at least 12 characters' })
  .refine((p) => [...p].length <= 128, { message: 'must be at most 128 characters' });

/** For checking an existing password: no policy, only a bound. */
export const AnyPassword = z
  .string()
  .min(1)
  .max(512)
  .transform((p) => p.normalize('NFKC'));

export const OpaqueToken = z
  .string()
  .min(20)
  .max(200)
  .regex(/^[A-Za-z0-9_-]+$/);

export const Platform = z.enum(['android', 'web']);

export const Gender = z.enum(['boy', 'girl']);
export const Palette = z.enum(['automatic', 'ocean', 'berry', 'forest']);
export const DisplayName = z
  .string()
  .max(24)
  .regex(/^[\p{L}\p{M} '’-]*$/u, 'only letters, spaces, hyphens and apostrophes');
export const Avatar = z.number().int().min(0).max(2);

export const ChildFields = z.strictObject({
  displayName: DisplayName,
  gender: Gender,
  avatar: Avatar,
  palette: Palette,
});
export type ChildFields = z.infer<typeof ChildFields>;

export const ChildPatch = z
  .strictObject({
    displayName: DisplayName.optional(),
    gender: Gender.optional(),
    avatar: Avatar.optional(),
    palette: Palette.optional(),
  })
  .refine((p) => Object.keys(p).length > 0, { message: 'at least one field' });
export type ChildPatch = z.infer<typeof ChildPatch>;

const Voice = z.string().max(200).nullable();
export const Settings = z.strictObject({
  arabic: z.boolean(),
  breakMinutes: z.number().int().min(5).max(30),
  sound: z.boolean(),
  music: z.boolean(),
  narration: z.boolean(),
  volume: z.number().min(0).max(1),
  boyVoice: Voice,
  girlVoice: Voice,
});
export type Settings = z.infer<typeof Settings>;

export const SettingsPatch = z
  .strictObject({
    arabic: z.boolean().optional(),
    breakMinutes: z.number().int().min(5).max(30).optional(),
    sound: z.boolean().optional(),
    music: z.boolean().optional(),
    narration: z.boolean().optional(),
    volume: z.number().min(0).max(1).optional(),
    boyVoice: Voice.optional(),
    girlVoice: Voice.optional(),
  })
  .refine((p) => Object.keys(p).length > 0, { message: 'at least one field' });
export type SettingsPatch = z.infer<typeof SettingsPatch>;

/** The app's defaults (`AppSettings()` in lib/core/models.dart). */
export const DEFAULT_SETTINGS: Settings = {
  arabic: true,
  breakMinutes: 12,
  sound: true,
  music: true,
  narration: true,
  volume: 0.85,
  boyVoice: null,
  girlVoice: null,
};

export const Curriculum = z
  .string()
  .min(1)
  .max(40)
  .regex(/^[a-z0-9][a-z0-9._-]*$/);
export const UnitId = z
  .string()
  .min(1)
  .max(64)
  .regex(/^[A-Za-z0-9][A-Za-z0-9._-]*$/);
export const JourneyKey = z
  .string()
  .min(1)
  .max(128)
  .regex(/^[A-Za-z0-9][A-Za-z0-9._:-]*$/);
export const LocalDay = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
export const LocalDateTime = z
  .string()
  .max(40)
  .regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,9})?(Z|[+-]\d{2}:\d{2})?$/);
export const Outcome = z.enum(['firstTry', 'afterHint', 'explained']);

export const AttemptFields = z.strictObject({
  curriculum: Curriculum,
  unitId: UnitId,
  contentVersion: z.number().int().min(0).max(100000),
  completed: z.boolean(),
  effortStars: z.number().int().min(0).max(3),
  completedAt: LocalDateTime,
  clientAttemptId: z.string().max(128),
  objectives: z
    .record(z.string().min(1).max(128), Outcome)
    .refine((o) => Object.keys(o).length <= 200, { message: 'at most 200 objectives' }),
});
export type AttemptFields = z.infer<typeof AttemptFields>;

/** Journey state is the app's own typed model; the server bounds its shape and size. */
export const MAX_JOURNEY_BYTES = 64 * 1024;
export const JourneyState = z
  .record(z.string(), z.unknown())
  .refine((s) => Buffer.byteLength(JSON.stringify(s), 'utf8') <= MAX_JOURNEY_BYTES, {
    message: `must be at most ${MAX_JOURNEY_BYTES} bytes`,
  });
export const JourneyFields = z.strictObject({
  state: JourneyState,
  contentVersion: z.number().int().min(0).nullable().optional(),
});
export type JourneyFields = z.infer<typeof JourneyFields>;

// ---- auth ------------------------------------------------------------------
export const RegisterRequest = z.strictObject({
  email: Email,
  password: Password,
  consentVersion: z.string().min(1).max(40),
});
export const TokenRequest = z.strictObject({ token: OpaqueToken });
export const EmailRequest = z.strictObject({ email: Email });
export const PasswordRequest = z.strictObject({ password: AnyPassword });
export const LoginRequest = z.strictObject({
  email: Email,
  password: AnyPassword,
  deviceId: Uuid,
  platform: Platform,
});
/** A Google ID token is a JWT: three base64url parts. */
export const GoogleIdToken = z
  .string()
  .min(20)
  .max(4096)
  .regex(/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/);
export const GoogleLoginRequest = z.strictObject({
  idToken: GoogleIdToken,
  deviceId: Uuid,
  platform: Platform,
  consentVersion: z.string().min(1).max(40).optional(),
});
/** Account deletion: the password, or a fresh Google sign-in for Google-only accounts. */
export const DeleteAccountRequest = z.union([
  z.strictObject({ password: AnyPassword }),
  z.strictObject({ googleIdToken: GoogleIdToken }),
]);
export const RefreshRequest = z.strictObject({ refreshToken: OpaqueToken.optional() });
export const LogoutRequest = z.strictObject({ all: z.boolean().optional() });
export const ResetPasswordRequest = z.strictObject({ token: OpaqueToken, newPassword: Password });
export const ChangePasswordRequest = z.strictObject({
  currentPassword: AnyPassword,
  newPassword: Password,
});

// ---- devices and children ------------------------------------------------
export const DeviceRequest = z.strictObject({ id: Uuid, platform: Platform });
export const CreateChildRequest = ChildFields.extend({ id: Uuid, settings: Settings.optional() });
export const UpdateChildRequest = z
  .strictObject({
    displayName: DisplayName.optional(),
    gender: Gender.optional(),
    avatar: Avatar.optional(),
    palette: Palette.optional(),
    baseVersion: z.number().int().min(1),
  })
  .refine((p) => Object.keys(p).length > 1, { message: 'at least one field' });
export const PutSettingsRequest = Settings.extend({ baseVersion: z.number().int().min(1) });
export const AttemptQuery = z.strictObject({
  unitId: UnitId.optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

// ---- sync ------------------------------------------------------------------
const MutationId = { mutationId: Uuid };

export const ChildCreateMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('child'),
  op: z.literal('create'),
  id: Uuid,
  payload: ChildFields.extend({ settings: Settings.optional() }),
});
export const ChildPatchMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('child'),
  op: z.literal('patch'),
  id: Uuid,
  baseVersion: z.number().int().min(1),
  payload: ChildPatch,
  base: ChildPatch.optional(),
});
export const ChildDeleteMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('child'),
  op: z.literal('delete'),
  id: Uuid,
});
export const SettingsPatchMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('settings'),
  op: z.literal('patch'),
  childId: Uuid,
  baseVersion: z.number().int().min(1),
  payload: SettingsPatch,
  base: SettingsPatch.optional(),
});
export const AttemptCreateMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('attempt'),
  op: z.literal('create'),
  id: Uuid,
  childId: Uuid,
  payload: AttemptFields,
});
export const AttemptDeleteMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('attempt'),
  op: z.literal('delete'),
  id: Uuid,
  childId: Uuid,
});
export const JourneyPutMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('journey'),
  op: z.literal('put'),
  childId: Uuid,
  curriculum: Curriculum,
  key: JourneyKey,
  baseVersion: z.number().int().min(0),
  payload: JourneyFields,
});
export const JourneyDeleteMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('journey'),
  op: z.literal('delete'),
  childId: Uuid,
  curriculum: Curriculum,
  key: JourneyKey,
});
export const UsagePutMutation = z.strictObject({
  ...MutationId,
  entity: z.literal('usage'),
  op: z.literal('put'),
  childId: Uuid,
  day: LocalDay,
  payload: z.strictObject({ seconds: z.number().int().min(0).max(86400) }),
});

export const Mutation = z.union([
  ChildCreateMutation,
  ChildPatchMutation,
  ChildDeleteMutation,
  SettingsPatchMutation,
  AttemptCreateMutation,
  AttemptDeleteMutation,
  JourneyPutMutation,
  JourneyDeleteMutation,
  UsagePutMutation,
]);
export type Mutation = z.infer<typeof Mutation>;

/**
 * The envelope is validated strictly; each mutation is validated on its own
 * so one bad mutation is `rejected` without failing the whole batch.
 */
export const PushRequest = z.strictObject({
  deviceId: Uuid,
  platform: Platform.optional(),
  mutations: z
    .array(
      z.looseObject({
        mutationId: Uuid,
      }),
    )
    .min(1)
    .max(100),
});

export const PullQuery = z.strictObject({
  since: z.coerce.number().int().min(0).default(0),
  limit: z.coerce.number().int().min(1).max(500).default(200),
});
