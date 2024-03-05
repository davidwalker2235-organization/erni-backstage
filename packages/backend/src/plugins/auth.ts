import {
  createRouter,
  providers,
  defaultAuthProviderFactories,
} from '@backstage/plugin-auth-backend';
import { Router } from 'express';
import { PluginEnvironment } from '../types';

export default async function createPlugin(
    env: PluginEnvironment,
): Promise<Router> {
  return await createRouter({
    logger: env.logger,
    config: env.config,
    database: env.database,
    discovery: env.discovery,
    tokenManager: env.tokenManager,
    providerFactories: {
      ...defaultAuthProviderFactories,
      github: providers.github.create({
        signIn: {
          resolver(_, ctx) {
            const userRef = 'user:default/guest'; // Must be a full entity reference
            return ctx.issueToken({
              claims: {
                sub: userRef, // The user's own identity
                ent: [userRef], // A list of identities that the user claims ownership through
              },
            });
          },
        },
      }),
      // @ts-ignore
      'azure-easyauth': providers.easyAuth.create({
        signIn: {
          resolver: async (info, ctx) => {
            const {
              fullProfile: { id },
            } = info.result;

            if (!id) {
              throw new Error('User profile contained no id');
            }

            return await ctx.signInWithCatalogUser({
              annotations: {
                'graph.microsoft.com/user-id': id,
              },
            });
          },
        },
      }),
    },
  });
}