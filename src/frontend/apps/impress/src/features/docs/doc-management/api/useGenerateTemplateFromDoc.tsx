import { useMutation } from '@tanstack/react-query';
import { APIError, errorCauses, fetchAPI } from '@/api';
import { Template } from '@/docs/doc-export/types';

interface GenerateTemplateParams {
  docId: string;
  title?: string;
  description?: string;
}

export const generateTemplateFromDoc = async ({
  docId,
  title,
  description,
}: GenerateTemplateParams): Promise<Template> => {
  const response = await fetchAPI(`templates/${docId}/generate/`, {
    method: 'POST',
    body: JSON.stringify({ title, description }),
    headers: { 'Content-Type': 'application/json' },
  });

  if (!response.ok) {
    throw new APIError(
      'Failed to generate template',
      await errorCauses(response),
    );
  }

  return response.json() as Promise<Template>;
};

export function useGenerateTemplateFromDoc() {
  return useMutation<Template, APIError, GenerateTemplateParams>({
    mutationFn: generateTemplateFromDoc,
  });
}
