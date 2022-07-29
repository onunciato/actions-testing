const octokit = require("@octokit/rest");

(async () => {
    const auth = process.env.GITHUB_TOKEN;
    const [ owner, repo ] = process.env.GITHUB_REPOSITORY.split("/");
    const username = process.env.GITHUB_ACTOR;
    const client = new octokit.Octokit({ auth });
    
    console.log({ owner, repo, username });

    try {
        const result = await client.repos.getCollaboratorPermissionLevel({ owner, repo, username });
        console.log(result.data.permission);
    }
    catch (err) {
        throw err;
        console.log("none");
    }
})();
