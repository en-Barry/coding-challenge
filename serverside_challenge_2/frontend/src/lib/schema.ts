import { z } from "zod";
import { VALID_AMPERES, MAX_KWH } from "@/lib/constants";

const [first, ...rest] = VALID_AMPERES;
export const simulationFormSchema = z.object({
  ampere: z.union([z.literal(first), ...rest.map((a) => z.literal(a))]),
  kwh: z.coerce
    .number({ invalid_type_error: "使用量を入力してください" })
    .int("整数を入力してください")
    .min(0, "0以上を入力してください")
    .max(MAX_KWH, `${MAX_KWH}以下を入力してください`),
});

export type SimulationFormValues = z.infer<typeof simulationFormSchema>;
