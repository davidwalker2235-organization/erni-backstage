import {
  createRouter,
  providers,
  defaultAuthProviderFactories,
} from '@backstage/plugin-auth-backend';
import { Router } from 'express';
import { PluginEnvironment } from '../types';
import {DEFAULT_NAMESPACE, stringifyEntityRef} from "@backstage/catalog-model";

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
          resolver({profile}, ctx) {
            if (!profile.email) {
              throw new Error(
                  'Login failed. User does not contain an email'
              )
            }
            const [localPart] = profile.email.split('@')
            const userEntityRef = stringifyEntityRef({
              kind: 'User',
              name: localPart,
              namespace: DEFAULT_NAMESPACE
            })
            return ctx.issueToken({
              claims: {
                sub: userEntityRef,
                ent: [userEntityRef]
              },
            });
          },
          // resolver: providers.github.resolvers.usernameMatchingUserEntityName(),
        },
      }),
      // 'azure-easyauth': providers.easyAuth.create({
      //   signIn: {
      //     resolver: async (info, ctx) => {
      //       const {
      //         fullProfile: { id },
      //       } = info.result;
      //
      //       if (!id) {
      //         throw new Error('User profile contained no id');
      //       }
      //
      //       return await ctx.signInWithCatalogUser({
      //         annotations: {
      //           'graph.microsoft.com/user-id': id,
      //         },
      //       });
      //     },
      //   },
      // }),
      microsoft: providers.microsoft.create({
        signIn: {
          resolver({profile}, ctx) {
            if (!profile.email) {
              throw new Error(
                  'Login failed. User does not contain an email'
              )
            }
            const [localPart] = profile.email.split('@')
            const userEntityRef = stringifyEntityRef({
              kind: 'User',
              name: localPart,
              namespace: DEFAULT_NAMESPACE
            })

            return ctx.issueToken({
              claims: {
                sub: userEntityRef,
                ent: [userEntityRef]
              }
            })
          },
        },
      }),
    },
  });
}