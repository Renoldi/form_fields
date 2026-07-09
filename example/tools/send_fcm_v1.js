// Node.js script to send FCM HTTP v1 message using a service account JSON
// Usage:
//   npm install google-auth-library axios
//   node example/tools/send_fcm_v1.js path/to/service-account.json <DEVICE_TOKEN>

const { GoogleAuth } = require("google-auth-library");
const axios = require("axios");
const fs = require("fs");

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.error(
      "Usage: node send_fcm_v1.js <service_account.json> <device_token>",
    );
    process.exit(2);
  }
  const [saPath, deviceToken] = args;

  if (!fs.existsSync(saPath)) {
    console.error("Service account file not found:", saPath);
    process.exit(2);
  }

  const sa = JSON.parse(fs.readFileSync(saPath, "utf8"));
  const projectId = sa.project_id;
  if (!projectId) {
    console.error("project_id not found in service account file");
    process.exit(2);
  }

  const auth = new GoogleAuth({
    keyFile: saPath,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });

  const client = await auth.getClient();
  const accessToken = (await client.getAccessToken()).token;

  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const msg = {
    message: {
      token: deviceToken,
      notification: {
        title: "Test (v1)",
        body: "Hello from HTTP v1 example",
      },
      data: { source: "v1_example" },
    },
  };

  try {
    const resp = await axios.post(url, msg, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    });
    console.log("Success:", resp.data);
  } catch (err) {
    if (err.response)
      console.error("Error:", err.response.status, err.response.data);
    else console.error("Error:", err.message);
    process.exit(1);
  }
}

main();
