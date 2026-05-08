import { z } from "zod";
import { VALID_AMPERES, MAX_KWH } from "@/lib/constants";

const [first, ...rest] = VALID_AMPERES;
export const simulationFormSchema = z.object({
  ampere: z.union([z.literal(first), ...rest.map((a) => z.literal(a))]),
  // type="number" の input は空のとき空文字列になるため string で受け取り number に変換する
  kwh: z
    .string()
    .min(1, "使用量を入力してください")
    .pipe(
      z.coerce
        .number({ invalid_type_error: "数値を入力してください" })
        .int("整数を入力してください")
        .min(0, "0以上を入力してください")
        .max(MAX_KWH, `${MAX_KWH}以下を入力してください`)
    ),
});

export type SimulationFormValues = z.infer<typeof simulationFormSchema>;
