import { z } from 'zod';

const roleSchema = z.enum(['user', 'assistant', 'system']);

export const messageSchema = z.object({
  role: roleSchema,
  content: z.string().min(1).max(100_000),
});

export const chatRequestSchema = z.object({
  model: z.string().min(1).max(256),
  messages: z.array(messageSchema).min(1).max(80),
  skillId: z.string().max(64).optional().default('none'),
  systemPrompt: z.string().max(200_000).optional(),
  temperature: z.number().min(0).max(2).optional(),
  stream: z.boolean().optional().default(true),
});

const manifestSkillSchema = z.object({
  id: z.string().min(1).max(64),
  name: z.string().min(1).max(128),
  description: z.string().max(512),
  file: z.string().max(256).optional(),
  keywords: z.array(z.string().max(64)).optional(),
});

export const skillsCatalogPutSchema = z.object({
  manifest: z.object({
    version: z.number().int().min(1).optional(),
    skills: z.array(manifestSkillSchema).min(1).max(32),
  }),
  bodies: z.record(z.string(), z.string().max(200_000)),
});
