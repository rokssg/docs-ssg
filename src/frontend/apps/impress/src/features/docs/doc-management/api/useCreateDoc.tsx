import { useMutation, useQueryClient } from '@tanstack/react-query';

import { APIError, errorCauses, fetchAPI } from '@/api';

import { Doc } from '../types';

import { KEY_LIST_DOC } from './useDocs';

export const createDoc = async (): Promise<Doc> => {
  const response = await fetchAPI(`documents/`, {
    method: 'POST',
  });

  if (!response.ok) {
    throw new APIError('Failed to create the doc', await errorCauses(response));
  }

  return response.json() as Promise<Doc>;
};

export const createDocFromTemplate = async (templateId: string): Promise<Doc> => {
  const response = await fetchAPI(`documents/template/${templateId}`, {
    method: 'POST',
  });

  if (!response.ok) {
    throw new APIError('Failed to create the doc from template', await errorCauses(response));
  }

  return response.json() as Promise<Doc>;
};

interface CreateDocProps {
  onSuccess: (data: Doc) => void;
}

export function useCreateDoc({ onSuccess }: CreateDocProps) {
  const queryClient = useQueryClient();
  return useMutation<Doc, APIError>({
    mutationFn: createDoc,
    onSuccess: (data) => {
      void queryClient.resetQueries({
        queryKey: [KEY_LIST_DOC],
      });
      onSuccess(data);
    },
  });
}

export function useCreateDocFromTemplate({ onSuccess }: CreateDocProps) {
  const queryClient = useQueryClient();
  return useMutation<Doc, APIError, { templateId: string }>({
    mutationFn: ({ templateId }) => createDocFromTemplate(templateId),
    onSuccess: (data) => {
      void queryClient.resetQueries({
        queryKey: [KEY_LIST_DOC],
      }); 
      onSuccess(data);
    },
  });
}
