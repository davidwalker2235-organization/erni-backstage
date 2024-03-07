import {githubAuthApiRef, microsoftAuthApiRef} from "@backstage/core-plugin-api";

export const providers = [
    {
        id: 'github-auth-provider',
        title: 'Github',
        message: 'Sign in using Github',
        apiRef: githubAuthApiRef
    },
    {
        id: 'microsoft-auth-provider',
        title: 'Azure Active Directory',
        message: 'Sign in using Azure AD',
        apiRef: microsoftAuthApiRef
    }
]