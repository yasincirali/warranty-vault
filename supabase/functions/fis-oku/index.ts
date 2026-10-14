// fis-oku: receipt / invoice photo → structured draft for the "Doğru mu?" screen.
//
// Decisions:
// - Haiku 5.5 reads first (cheap, most receipts are simple). If it refuses,
//   fails the schema, or reports low confidence on the date (the field every
//   deadline hangs on), Sonnet 5.5 reads the same image once more.
// - The model returns a confidence per field; the app flags anything under
//   0.85 instead of trusting it. We never "fix" a field server-side.
// - Fail-closed feature switch: without FIS_OKU_ACIK=1 nothing is spent.
// - The response never carries provider error text, keys or raw output.
// - Only signed-in users (gateway verifies the JWT; we re-check the user).
import Anthropic from "npm:@anthropic-ai/sdk@0.134.0";
import { zodOutputFormat } from "npm:@anthropic-ai/sdk@0.134.0/helpers/zod";
import { z } from "npm:zod@4";
import { createClient } from "npm:@supabase/supabase-js@2";

const conf = z.number().min(0).max(1);
export const Draft = z.object({
  product: z.object({ value: z.string(), confidence: conf }),
  store: z.object({ value: z.string(), confidence: conf }),
  purchase_date: z.object({ value: z.string().describe("YYYY-MM-DD"), confidence: conf }),
  amount: z.object({ value: z.number(), currency: z.string().length(3), confidence: conf }),
  serial: z.object({ value: z.string().nullable(), confidence: conf }),
  country: z.string().length(2).describe("ISO 3166-1 alpha-2 of the store"),
  channel: z.enum(["store", "online"]),
  manufacturer_warranty_months: z.number().int().nullable(),
});
export type Draft = z.infer<typeof Draft>;

const PROMPT = `Read this receipt or invoice for a warranty tracker.
Fill every field. For each confidence, give your honest probability that the
value is exactly right; faded or partly hidden text must get a low score.
Use null when a value is not on the document. Do not guess a serial number.
If several products are listed, use the most expensive one.`;

const SURE = 0.85;
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

async function read(client: Anthropic, model: string, image: string, mediaType: string) {
  const res = await client.messages.parse({
    model,
    max_tokens: 4000,
    output_config: { effort: "low", format: zodOutputFormat(Draft) },
    messages: [{
      role: "user",
      content: [
        { type: "image", source: { type: "base64", media_type: mediaType as "image/jpeg", data: image } },
        { type: "text", text: PROMPT },
      ],
    }],
  });
  if (res.stop_reason === "refusal" || !res.parsed_output) return null;
  return res.parsed_output;
}

Deno.serve(async (req) => {
  if (Deno.env.get("FIS_OKU_ACIK") !== "1") return json(503, { error: "disabled" });
  if (req.method !== "POST") return json(405, { error: "method" });

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return json(401, { error: "auth" });

  const { image, media_type } = await req.json().catch(() => ({}));
  if (typeof image !== "string" || !/^image\/(jpeg|png|webp)$/.test(media_type ?? "")) {
    return json(400, { error: "input" });
  }

  // TODO(fis-oku): per-user daily limit (free tier) before any model call.
  const client = new Anthropic(); // ANTHROPIC_API_KEY from function secrets
  try {
    let draft = await read(client, "claude-haiku-5-5", image, media_type);
    let model = "haiku";
    if (!draft || draft.purchase_date.confidence < SURE) {
      draft = await read(client, "claude-sonnet-5-5", image, media_type) ?? draft;
      model = "sonnet";
    }
    if (!draft) return json(422, { error: "unreadable" });
    return json(200, { draft, model });
  } catch (e) {
    // Log the class only; provider messages never leave the function.
    console.error("fis-oku", e instanceof Anthropic.APIError ? e.status : "unknown");
    return json(502, { error: "reader" });
  }
});
