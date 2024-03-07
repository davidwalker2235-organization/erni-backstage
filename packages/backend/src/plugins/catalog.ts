import { CatalogBuilder } from '@backstage/plugin-catalog-backend';
import { ScaffolderEntitiesProcessor } from '@backstage/plugin-catalog-backend-module-scaffolder-entity-model';
import { Router } from 'express';
import { PluginEnvironment } from '../types';
import { GithubOrgEntityProvider, GithubOrgReaderProcessor } from '@backstage/plugin-catalog-backend-module-github';

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  const builder = await CatalogBuilder.create(env);
  // The org URL below needs to match a configured integrations.github entry
  // specified in your app-config.
  builder.addProcessor(
      GithubOrgReaderProcessor.fromConfig(env.config, { logger: env.logger }),
  );
  builder.addEntityProvider(
      GithubOrgEntityProvider.fromConfig(env.config, {
        id: 'development',
        orgUrl: 'https://github.com/davidwalker2235-organization',
        logger: env.logger,
        schedule: env.scheduler.createScheduledTaskRunner({
          frequency: { minutes: 60 },
          timeout: { minutes: 15 },
        }),
      }),
  );
  builder.addProcessor(new ScaffolderEntitiesProcessor());
  const { processingEngine, router } = await builder.build();
  await processingEngine.start();
  return router;
}
