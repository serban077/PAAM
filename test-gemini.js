const { GoogleGenerativeAI } = require("@google/generative-ai");
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
async function run() {
  const model = genAI.getGenerativeModel({ model: "gemini-pro"});
  const result = await model.generateContent("Salut, funcționezi?");
  console.log(result.response.text());
}
run();
