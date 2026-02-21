import { useModal } from '@openfun/cunningham-react';
import { useTranslation } from 'react-i18next';
import { useState } from 'react';
import { GenerateTemplateModal } from './GenerateTemplateModal';
import { useToastProvider, VariantType } from '@openfun/cunningham-react';
import { useGenerateTemplateFromDoc } from '@/docs/doc-management/api/useGenerateTemplateFromDoc';

import { DropdownMenu, DropdownMenuOption, Icon } from '@/components';
import {
  Doc,
  KEY_LIST_DOC,
  ModalRemoveDoc,
  useCreateFavoriteDoc,
  useDeleteFavoriteDoc,
} from '@/docs/doc-management';

interface DocsGridActionsProps {
  doc: Doc;
  openShareModal?: () => void;
}

export const DocsGridActions = ({
  doc,
  openShareModal,
}: DocsGridActionsProps) => {
  const { t } = useTranslation();
  const [isTemplateModalOpen, setTemplateModalOpen] = useState(false);
  const { toast } = useToastProvider();
  const generateTemplate = useGenerateTemplateFromDoc();

  const deleteModal = useModal();

  const removeFavoriteDoc = useDeleteFavoriteDoc({
    listInvalideQueries: [KEY_LIST_DOC],
  });
  const makeFavoriteDoc = useCreateFavoriteDoc({
    listInvalideQueries: [KEY_LIST_DOC],
  });

  const handleGenerateTemplate = async (title: string) => {
    try {
      await generateTemplate.mutateAsync({ docId: doc.id, title });
      toast(t('Template generated successfully'), VariantType.SUCCESS);
    } catch (e) {
      toast(t('Failed to generate template'), VariantType.ERROR);
    } finally {
      setTemplateModalOpen(false);
    }
  };

  const options: DropdownMenuOption[] = [
    {
      label: doc.is_favorite ? t('Unpin') : t('Pin'),
      icon: 'push_pin',
      callback: () => setTemplateModalOpen(true),
      testId: `docs-grid-actions-${doc.is_favorite ? 'unpin' : 'pin'}-${doc.id}`,
    },
    {
      label: t('Share'),
      icon: 'group',
      callback: () => {
        openShareModal?.();
      },

      testId: `docs-grid-actions-share-${doc.id}`,
    },
    {
      label: t('Template'),
      icon: 'copy',
      callback: async () => setTemplateModalOpen(true),
      testId: `docs-grid-actions-generate-template-${doc.id}`,
    },
    {
      label: t('Remove'),
      icon: 'delete',
      callback: () => deleteModal.open(),
      disabled: !doc.abilities.destroy,
      testId: `docs-grid-actions-remove-${doc.id}`,
    },
  ];

  return (
    <>
      <DropdownMenu options={options}>
        <Icon
          data-testid={`docs-grid-actions-button-${doc.id}`}
          iconName="more_horiz"
          $theme="primary"
          $variation="600"
        />
      </DropdownMenu>

      {deleteModal.isOpen && (
        <ModalRemoveDoc onClose={deleteModal.onClose} doc={doc} />
      )}

      <GenerateTemplateModal
        isOpen={isTemplateModalOpen}
        initialTitle={doc.title ?? 'Lorem ipsum'}
        onClose={() => setTemplateModalOpen(false)}
        onConfirm={handleGenerateTemplate}
      />
    </>
  );
};
